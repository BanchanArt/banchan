defmodule BanchanWeb.CommissionLive.InvoiceTest do
  @moduledoc """
  Test for the creating and managing invoices on the commissions page.
  """
  use BanchanWeb.ConnCase, async: true

  import Mox
  import Phoenix.LiveViewTest

  import Banchan.CommissionsFixtures

  alias Banchan.Commissions
  alias Banchan.Notifications

  setup :verify_on_exit!

  setup do
    commission = commission_fixture()

    on_exit(fn -> Notifications.wait_for_notifications() end)

    %{
      commission: commission,
      client: commission.client,
      studio: commission.studio,
      artist: Enum.at(commission.studio.artists, 0)
    }
  end

  describe "submitting an invoice" do
    test "invoice basic", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission
    } do
      artist_conn = log_in_user(conn, artist)

      {:ok, page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      page_live
      |> form("#comment-box form", %{"event[text]": "foo", "event[amount]": "420"})
      |> render_submit()

      Notifications.wait_for_notifications()

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      refute invoice_box =~ "Payment is Requested"
      assert invoice_box =~ "Waiting for Payment"
      assert invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Pay</
      refute invoice_box =~ "modal-open"

      client_conn = log_in_user(conn, client)

      {:ok, page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "Payment is requested"
      refute invoice_box =~ "Waiting for Payment"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      assert invoice_box =~ ~r/<button[^<]+Pay</
      refute invoice_box =~ "modal-open"
    end
  end

  describe "responding to invoice" do
    test "expiring invoice", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission
    } do
      artist_conn = log_in_user(conn, artist)

      invoice_fixture(artist, commission, %{
        "amount" => Money.new(42_000, :USD),
        "text" => "Please pay me :("
      })

      {:ok, page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      page_live
      |> element(".invoice-box .cancel-payment-request")
      |> render_click()

      Notifications.wait_for_notifications()

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "Payment session expired"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Pay</

      client_conn = log_in_user(conn, client)

      {:ok, page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "Payment session expired"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Pay</
    end

    test "paying an invoice", %{
      conn: conn,
      artist: artist,
      client: client,
      studio: studio,
      commission: commission
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)
      platform_fee = Money.multiply(Money.add(amount, tip), studio.platform_fee)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :("
        })

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      line_items = [
        %{
          name: "Commission Invoice Payment",
          quantity: 1,
          amount: amount.amount,
          currency: String.downcase(to_string(amount.currency))
        },
        %{
          name: "Extra Tip",
          quantity: 1,
          amount: tip.amount,
          currency: String.downcase(to_string(tip.currency))
        }
      ]

      return_path = Routes.commission_path(client_conn, :show, commission.public_id)
      # NOTE: The www.example.com comes from Plug.Adapters.Test, because
      # Phoenix.ConnCase doesn't actually set a hostname
      return_url = "http://www.example.com#{return_path}#event-#{invoice.event.public_id}"

      stripe_sess_id = "stripe_sess_mock_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:create_session, fn params ->
        assert ["card"] == params.payment_method_types
        assert "payment" == params.mode
        assert return_url == params.cancel_url
        assert return_url == params.success_url
        assert line_items == params.line_items

        assert %{
                 application_fee_amount: platform_fee.amount,
                 transfer_data: %{
                   destination: studio.stripe_id
                 }
               } == params.payment_intent_data

        {:ok, %Stripe.Session{id: stripe_sess_id, url: "https://some.stripe.url"}}
      end)

      client_page_live
      |> form(".invoice-box form", %{"event[amount]": "69"})
      |> render_submit()

      assert_redirected(client_page_live, "https://some.stripe.url")

      Notifications.wait_for_notifications()

      # Page from the artist's perspective
      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "Payment session in progress"
      assert invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Continue Payment</

      # Back to the client

      # Reload because we killed the previous view on redirect
      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "Payment session in progress"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      assert invoice_box =~ ~r/<button[^<]+Continue Payment</

      client_page_live
      |> element(".invoice-box .continue-payment")
      |> render_click()

      assert_redirected(client_page_live, "https://some.stripe.url")

      intent_id = "stripe_intent_mock_id#{System.unique_integer()}"
      txn_id = "stripe_txn_mock_id#{System.unique_integer()}"
      # Let's complete the session
      Banchan.StripeAPI.Mock
      |> expect(:retrieve_payment_intent, fn id, _params, _opts ->
        assert intent_id == id
        {:ok, %Stripe.PaymentIntent{id: id, charges: %{data: [%{balance_transaction: txn_id}]}}}
      end)
      |> expect(:retrieve_balance_transaction, fn id, _opts ->
        assert txn_id == id

        {:ok,
         %Stripe.BalanceTransaction{
           id: id,
           available_on: 1,
           amount: (amount |> Money.add(tip) |> Money.subtract(platform_fee)).amount,
           currency: "usd"
         }}
      end)

      Commissions.process_payment_succeeded!(%Stripe.Session{
        id: stripe_sess_id,
        payment_intent: intent_id
      })

      Notifications.wait_for_notifications()

      # Check client

      # Reload after redirect
      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "Payment succeeded"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Continue Payment</

      # Check artist
      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "Payment succeeded"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Continue Payment</
    end
  end

  describe "refunding an invoice" do
    test "successful refund" do
    end

    test "refunding after release" do
    end
  end

  describe "releasing an invoice" do
    test "successfully releasing invoice" do
    end
  end
end
