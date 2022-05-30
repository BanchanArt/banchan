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
  alias Banchan.Commissions.{Commission, Invoice}
  alias Banchan.Repo

  def commission_fixture(attrs \\ %{}) do
    user = user_fixture()
    studio = studio_fixture([user])
    offering = offering_fixture(studio)

    {:ok, commission} =
      Commissions.create_commission(
        user,
        studio,
        offering,
        [],
        [],
        attrs
        |> Enum.into(%{
          title: "some title",
          description: "Some Description",
          tos_ok: true
        })
      )

    commission
  end

  def invoice_fixture(%User{} = actor, %Commission{} = commission, data) do
    {:ok, invoice} = Commissions.invoice(actor, commission, true, [], data)
    invoice
  end

  def checkout_session_fixture(%Invoice{} = invoice, %Money{} = tip) do
    commission = (invoice |> Repo.preload(:commission)).commission
    event = (invoice |> Repo.preload(event: [:invoice])).event
    client = (invoice |> Repo.preload(:client)).client
    checkout_uri = "https://stripe-mock-checkout-uri"
    sess_id = "stripe-mock-session-id#{System.unique_integer()}"

    Banchan.StripeAPI.Mock
    |> expect(:create_session, fn _sess ->
      {:ok,
       %Stripe.Session{
         id: sess_id,
         url: checkout_uri
       }}
    end)

    Commissions.process_payment!(client, event, commission, checkout_uri, tip)

    %Stripe.Session{
      id: sess_id,
      url: checkout_uri,
      payment_intent: "stripe-mock-payment-intent-id#{System.unique_integer()}"
    }
  end

  def succeed_mock_payment(
        %Stripe.Session{} = session,
        available_on \\ DateTime.add(DateTime.utc_now(), -2)
      ) do
    txn_id = "stripe-mock-transaction-id#{System.unique_integer()}"
    invoice = from(i in Invoice, where: i.stripe_session_id == ^session.id) |> Repo.one!()

    Banchan.StripeAPI.Mock
    |> expect(:retrieve_payment_intent, fn _, _, _ ->
      {:ok, %{charges: %{data: [%{balance_transaction: txn_id}]}}}
    end)
    |> expect(:retrieve_balance_transaction, fn _, _ ->
      {:ok,
       %{
         available_on: DateTime.to_unix(available_on),
         amount: Money.add(invoice.amount, invoice.tip).amount,
         currency: "usd"
       }}
    end)

    Commissions.process_payment_succeeded!(session)
  end

  def expire_mock_payment(%Stripe.Session{} = session) do
    Commissions.process_payment_expired!(session)
  end
end
