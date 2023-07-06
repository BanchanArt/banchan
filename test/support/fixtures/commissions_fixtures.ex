defmodule Banchan.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Commissions` context.
  """
  @dialyzer [:no_return]

  import Mox

  import Ecto.Query

  import Banchan.AccountsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Accounts.User
  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, LineItem}
  alias Banchan.Payments
  alias Banchan.Payments.Invoice
  alias Banchan.Repo

  def commission_fixture(attrs \\ %{}) do
    artist = Map.get(attrs, :artist) || user_fixture(%{roles: [:artist]})
    studio = Map.get(attrs, :studio) || studio_fixture([artist])
    offering = Map.get(attrs, :offering) || offering_fixture(studio)
    offering = Repo.preload(offering, :options)

    line_items =
      Map.get(attrs, :line_items) ||
        if Enum.empty?(offering.options) do
          [
            %LineItem{
              option: nil,
              amount: Money.new(42_000, studio.default_currency),
              name: "custom line item",
              description: "custom line item description"
            }
          ]
        else
          option = Enum.at(offering.options, 0)

          [
            %LineItem{
              option: option,
              amount: option.price,
              name: option.name,
              description: option.description
            }
          ]
        end

    {:ok, commission} =
      Commissions.create_commission(
        Map.get(attrs, :client) || user_fixture(),
        studio,
        offering,
        line_items,
        [],
        attrs
        |> Map.delete(:line_items)
        |> Enum.into(%{
          title: "some title",
          description: "Some Description",
          tos_ok: true,
          currency: Enum.at(line_items, 0).amount.currency
        })
      )

    commission |> Repo.preload(studio: [:artists])
  end

  def invoice_fixture(%User{} = actor, %Commission{} = commission, data, final? \\ false) do
    {:ok, invoice} = Payments.invoice(actor, commission, [], data, final?)
    invoice
  end

  def checkout_session_fixture(%Invoice{} = invoice, tip \\ Money.new(0, :USD)) do
    commission = (invoice |> Repo.preload(:commission)).commission
    event = (invoice |> Repo.preload(event: [:invoice])).event
    client = (invoice |> Repo.preload(:client)).client
    checkout_uri = "https://stripe-mock-checkout-uri"
    sess_id = "stripe-mock-session-id#{System.unique_integer()}"

    sess = %Stripe.Session{
      id: sess_id,
      url: checkout_uri,
      payment_intent: "stripe-mock-payment-intent-id#{System.unique_integer()}"
    }

    Banchan.StripeAPI.Mock
    |> expect(:create_session, fn _sess ->
      {:ok, sess}
    end)

    {:ok, _} = Payments.process_payment(client, event, commission, checkout_uri, tip)

    sess
  end

  def succeed_mock_payment!(
        %Stripe.Session{} = session,
        opts \\ []
      ) do
    charge_id = "stripe-mock-charge-id#{System.unique_integer()}"
    txn_id = "stripe-mock-transaction-id#{System.unique_integer()}"
    trans_id = "stripe-mock-transfer-id#{System.unique_integer()}"

    invoice = from(i in Invoice, where: i.stripe_session_id == ^session.id) |> Repo.one!()

    now_ish = DateTime.utc_now() |> DateTime.add(-2)

    Banchan.StripeAPI.Mock
    |> expect(:retrieve_payment_intent, fn _, _, _ ->
      {:ok,
       %{charges: %{data: [%{id: charge_id, balance_transaction: txn_id, transfer: trans_id}]}}}
    end)
    |> expect(:retrieve_balance_transaction, fn _, _ ->
      {:ok,
       %{
         available_on: Keyword.get(opts, :available_on, now_ish) |> DateTime.to_unix(),
         created: Keyword.get(opts, :paid_on, now_ish) |> DateTime.to_unix(),
         amount:
           (invoice.amount
            |> Money.add(invoice.tip)
            |> Money.subtract(invoice.platform_fee)).amount,
         currency: invoice.amount.currency |> to_string() |> String.downcase()
       }}
    end)
    |> expect(:retrieve_transfer, fn _ ->
      {:ok,
       %Stripe.Transfer{
         destination_payment: %{
           balance_transaction: %{
             amount:
               (invoice.amount
                |> Money.add(invoice.tip)
                |> Money.subtract(invoice.platform_fee)).amount,
             currency: invoice.amount.currency |> to_string() |> String.downcase()
           }
         }
       }}
    end)

    Payments.process_payment_succeeded!(session)
  end

  def expire_mock_payment(%Stripe.Session{} = session) do
    Payments.process_payment_expired!(session)
  end

  def mock_refund_stripe_calls(%Invoice{} = invoice) do
    refund_id = "stripe-mock-payment-refund-id#{System.unique_integer()}"

    refund = %Stripe.Refund{
      id: refund_id,
      status: "succeeded",
      amount: invoice.amount.amount,
      currency: invoice.amount.currency |> to_string() |> String.downcase()
    }

    Banchan.StripeAPI.Mock
    |> expect(:create_refund, fn %{
                                   charge: _incoming_charge_id,
                                   reverse_transfer: true,
                                   refund_application_fee: false
                                 },
                                 _ ->
      {:ok, refund}
    end)
  end

  def refund_mock_payment(actor, %Invoice{} = invoice) do
    mock_refund_stripe_calls(invoice)
    Payments.refund_payment(actor, invoice)
  end

  def payment_fixture(
        %User{} = actor,
        %Commission{} = commission,
        %Money{} = amount,
        %Money{} = tip,
        succeed \\ true,
        final? \\ false
      ) do
    invoice =
      invoice_fixture(
        actor,
        commission,
        %{
          "amount" => amount,
          "text" => "Please pay me :("
        },
        final?
      )

    session = checkout_session_fixture(invoice, tip)

    if succeed do
      succeed_mock_payment!(session)
    else
      expire_mock_payment(session)
    end

    session
  end

  def process_final_payment!(%Commission{} = commission, tip \\ Money.new(0, :USD)) do
    client = Repo.preload(commission, :client).client
    deposited = Commissions.deposited_amount(client, commission, false)
    estimate = Commissions.line_item_estimate(Repo.preload(commission, :line_items).line_items)
    studio = Repo.preload(commission, :studio).studio
    artist = Repo.preload(studio, :artists).artists |> Enum.at(0)
    payment_fixture(artist, commission, Money.subtract(estimate, deposited), tip, true, true)
  end
end
