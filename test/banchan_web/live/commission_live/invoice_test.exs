defmodule BanchanWeb.CommissionLive.InvoiceTest do
  @moduledoc """
  Test for the creating and managing invoices on the commissions page.
  """
  use BanchanWeb.ConnCase, async: true

  import ExUnit.CaptureLog
  import Mox
  import Phoenix.LiveViewTest

  import Banchan.CommissionsFixtures

  alias Banchan.Accounts
  alias Banchan.Notifications
  alias Banchan.Payments

  setup :verify_on_exit!

  setup do
    commission = commission_fixture()

    on_exit(fn -> Notifications.wait_for_notifications() end)

    %{
      commission: commission,
      client: commission.client,
      studio: commission.studio,
      artist: Enum.at(commission.studio.artists, 0),
      system: Accounts.system_user()
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
      |> form("#commission-invoice-collapse form", %{"event[text]": "foo", "event[amount]": "420"})
      |> render_submit()

      Notifications.wait_for_notifications()

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      refute invoice_box =~ "Payment is Requested"
      assert invoice_box =~ "Waiting for Payment"
      assert invoice_box =~ ~r/<button[^<]+Cancel Payment</
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
      assert invoice_box =~ "Payment Requested"
      refute invoice_box =~ "Waiting for Payment"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment</
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
          quantity: 1,
          price_data: %{
            currency: "usd",
            product_data: %{name: "Commission Invoice Payment"},
            tax_behavior: "exclusive",
            unit_amount: amount.amount
          }
        },
        %{
          quantity: 1,
          price_data: %{
            currency: "usd",
            product_data: %{name: "Extra Tip"},
            tax_behavior: "exclusive",
            unit_amount: tip.amount
          }
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
                 transfer_data: %{
                   amount: (amount |> Money.add(tip) |> Money.subtract(platform_fee)).amount,
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

      assert invoice_box =~ "Payment in Process"
      assert invoice_box =~ ~r/<button[^<]+Cancel Payment</
      refute invoice_box =~ ~r/<button[^<]+Continue Payment</

      # Back to the client

      # Reload because we killed the previous view on redirect
      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "Payment in Process"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment</
      assert invoice_box =~ ~r/<button[^<]+Continue Payment</

      client_page_live
      |> element(".invoice-box .continue-payment")
      |> render_click()

      assert_redirected(client_page_live, "https://some.stripe.url")

      intent_id = "stripe_intent_mock_id#{System.unique_integer()}"
      txn_id = "stripe_txn_mock_id#{System.unique_integer()}"
      trans_id = "stripe_transfer_mock_id#{System.unique_integer()}"

      # Let's complete the session
      Banchan.StripeAPI.Mock
      |> expect(:retrieve_payment_intent, fn id, _params, _opts ->
        assert intent_id == id

        {:ok,
         %Stripe.PaymentIntent{
           id: id,
           charges: %{data: [%{balance_transaction: txn_id, transfer: trans_id}]}
         }}
      end)
      |> expect(:retrieve_transfer, fn id ->
        assert id == trans_id

        {:ok,
         %Stripe.Transfer{
           id: trans_id,
           destination_payment: %{
             balance_transaction: %{
               amount: Money.add(amount, tip).amount,
               currency: amount.currency |> to_string |> String.downcase()
             }
           }
         }}
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

      Payments.process_payment_succeeded!(%Stripe.Session{
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

      assert invoice_box =~ "Payment Succeeded"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment</
      refute invoice_box =~ ~r/<button[^<]+Continue Payment</

      # Check artist
      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "Payment Succeeded"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment</
      refute invoice_box =~ ~r/<button[^<]+Continue Payment</
    end
  end

  describe "refunding an invoice" do
    test "successful refund", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)
      total = Money.add(amount, tip)

      session = payment_fixture(artist, commission, amount, tip)

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      refute artist_page_live
             |> has_element?(".invoice-box .modal.modal-open")

      refute client_page_live
             |> has_element?(".invoice-box .open-refund-modal")

      artist_page_live
      |> element(".invoice-box .open-refund-modal")
      |> render_click()

      refute client_page_live
             |> has_element?(".invoice-box .modal.modal-open")

      modal =
        artist_page_live
        |> element(".invoice-box .modal.modal-open")
        |> render()

      assert modal =~ "Confirm Refund"
      assert modal =~ "Are you sure you want to refund this payment?"
      assert modal =~ ~r/<button[^<]+Confirm</

      artist_page_live
      |> element(".invoice-box .refund-modal .close-modal")
      |> render_click()

      refute artist_page_live
             |> has_element?(".invoice-box .modal.modal-open")

      artist_page_live
      |> element(".invoice-box .open-refund-modal")
      |> render_click()

      assert artist_page_live
             |> has_element?(".invoice-box .modal.modal-open")

      intent_id = "stripe_intent_mock_id#{System.unique_integer()}"
      charge_id = "stripe_charge_mock_id#{System.unique_integer()}"
      refund_id = "stripe_refund_mock_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn id, _opts ->
        assert session.id == id
        {:ok, %Stripe.Session{id: id, payment_intent: intent_id}}
      end)
      |> expect(:retrieve_payment_intent, fn id, _params, _opts ->
        assert intent_id == id
        {:ok, %Stripe.PaymentIntent{id: id, charges: %{data: [%{id: charge_id}]}}}
      end)
      |> expect(:create_refund, fn params, _opts ->
        assert charge_id == params.charge
        assert true == params.reverse_transfer
        assert true == params.refund_application_fee

        {:ok,
         %Stripe.Refund{
           id: refund_id,
           status: "succeeded",
           amount: total.amount,
           currency: total.currency |> to_string() |> String.downcase()
         }}
      end)

      artist_page_live
      |> element(".invoice-box .modal .refund-btn")
      |> render_click()

      Notifications.wait_for_notifications()

      # ??? This is needed for CI to pass ???
      # I guess the has_element? doesn't actually ping the live view properly.
      artist_page_live |> render()

      refute artist_page_live
             |> has_element?(".invoice-box .modal.modal-open")

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "Payment has been refunded to the client"

      refute artist_page_live
             |> has_element?(".invoice-box .open-refund-modal")

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "Payment has been refunded to the client"

      refute client_page_live
             |> has_element?(".invoice-box .open-refund-modal")
    end

    test "refund error", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)

      payment_fixture(artist, commission, amount, tip)

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      artist_page_live
      |> element(".invoice-box .open-refund-modal")
      |> render_click()

      user_error = "Something bad happened"
      internal_error = "Something went poorly internally"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn _id, _opts ->
        {:error,
         %Stripe.Error{
           code: :request_failed,
           source: :stripe,
           message: internal_error,
           user_message: user_error
         }}
      end)

      log =
        capture_log([level: :error], fn ->
          artist_page_live
          |> element(".invoice-box .modal .refund-btn")
          |> render_click()

          Notifications.wait_for_notifications()
        end)

      assert log =~ internal_error
      assert log =~ user_error

      modal =
        artist_page_live
        |> element(".invoice-box .modal.modal-open")
        |> render()

      assert modal =~ "Confirm Refund"
      assert modal =~ "Are you sure you want to refund this payment?"

      assert modal =~ user_error
      refute modal =~ internal_error
      assert modal =~ ~r/<button[^<]+Confirm</
      refute modal =~ ~r/<button[^>]disabled/

      artist_page_live
      |> element(".invoice-box .refund-modal .close-modal")
      |> render_click()

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      # Request errors don't change invoice box state.
      refute invoice_box =~ "Refund failed"

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      refute invoice_box =~ "Refund failed"
    end

    test "refund pending after submission", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission,
      system: system
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)
      total = Money.add(amount, tip)

      session = payment_fixture(artist, commission, amount, tip)

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      artist_page_live
      |> element(".invoice-box .open-refund-modal")
      |> render_click()

      intent_id = "stripe_intent_mock_id#{System.unique_integer()}"
      charge_id = "stripe_charge_mock_id#{System.unique_integer()}"
      refund_id = "stripe_refund_mock_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn id, _opts ->
        assert session.id == id
        {:ok, %Stripe.Session{id: id, payment_intent: intent_id}}
      end)
      |> expect(:retrieve_payment_intent, fn id, _params, _opts ->
        assert intent_id == id
        {:ok, %Stripe.PaymentIntent{id: id, charges: %{data: [%{id: charge_id}]}}}
      end)
      |> expect(:create_refund, fn params, _opts ->
        assert charge_id == params.charge
        assert true == params.reverse_transfer
        assert true == params.refund_application_fee
        {:ok, %Stripe.Refund{id: refund_id, status: "pending"}}
      end)

      artist_page_live
      |> element(".invoice-box .modal .refund-btn")
      |> render_click()

      Notifications.wait_for_notifications()

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "A refund is pending"

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "A refund is pending"

      Payments.process_refund_updated(
        system,
        %Stripe.Refund{
          id: refund_id,
          status: "succeeded",
          amount: total.amount,
          currency: total.currency |> to_string() |> String.downcase()
        },
        nil
      )

      Notifications.wait_for_notifications()

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "Payment has been refunded to the client"

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "Payment has been refunded to the client"
    end

    test "refund canceled", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission,
      system: system
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)

      session = payment_fixture(artist, commission, amount, tip)

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      artist_page_live
      |> element(".invoice-box .open-refund-modal")
      |> render_click()

      intent_id = "stripe_intent_mock_id#{System.unique_integer()}"
      charge_id = "stripe_charge_mock_id#{System.unique_integer()}"
      refund_id = "stripe_refund_mock_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn id, _opts ->
        assert session.id == id
        {:ok, %Stripe.Session{id: id, payment_intent: intent_id}}
      end)
      |> expect(:retrieve_payment_intent, fn id, _params, _opts ->
        assert intent_id == id
        {:ok, %Stripe.PaymentIntent{id: id, charges: %{data: [%{id: charge_id}]}}}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:ok, %Stripe.Refund{id: refund_id, status: "pending"}}
      end)

      artist_page_live
      |> element(".invoice-box .modal .refund-btn")
      |> render_click()

      Payments.process_refund_updated(
        system,
        %Stripe.Refund{id: refund_id, status: "canceled"},
        nil
      )

      Notifications.wait_for_notifications()

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "A refund was submitted but was canceled"

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "A refund was submitted but was canceled"
    end

    test "refund needs further action", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission,
      system: system
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)

      session = payment_fixture(artist, commission, amount, tip)

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      artist_page_live
      |> element(".invoice-box .open-refund-modal")
      |> render_click()

      intent_id = "stripe_intent_mock_id#{System.unique_integer()}"
      charge_id = "stripe_charge_mock_id#{System.unique_integer()}"
      refund_id = "stripe_refund_mock_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn id, _opts ->
        assert session.id == id
        {:ok, %Stripe.Session{id: id, payment_intent: intent_id}}
      end)
      |> expect(:retrieve_payment_intent, fn id, _params, _opts ->
        assert intent_id == id
        {:ok, %Stripe.PaymentIntent{id: id, charges: %{data: [%{id: charge_id}]}}}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:ok, %Stripe.Refund{id: refund_id, status: "pending"}}
      end)

      artist_page_live
      |> element(".invoice-box .modal .refund-btn")
      |> render_click()

      Payments.process_refund_updated(
        system,
        %Stripe.Refund{id: refund_id, status: "requires_action"},
        nil
      )

      Notifications.wait_for_notifications()

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "A refund was submitted but requires further action."
      refute invoice_box =~ "Please check your email"

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "A refund was submitted but requires further action."
      assert invoice_box =~ "Please check your email"
    end

    test "refund failed", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission,
      system: system
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)

      session = payment_fixture(artist, commission, amount, tip)

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      artist_page_live
      |> element(".invoice-box .open-refund-modal")
      |> render_click()

      intent_id = "stripe_intent_mock_id#{System.unique_integer()}"
      charge_id = "stripe_charge_mock_id#{System.unique_integer()}"
      refund_id = "stripe_refund_mock_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn id, _opts ->
        assert session.id == id
        {:ok, %Stripe.Session{id: id, payment_intent: intent_id}}
      end)
      |> expect(:retrieve_payment_intent, fn id, _params, _opts ->
        assert intent_id == id
        {:ok, %Stripe.PaymentIntent{id: id, charges: %{data: [%{id: charge_id}]}}}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:ok, %Stripe.Refund{id: refund_id, status: "pending"}}
      end)

      artist_page_live
      |> element(".invoice-box .modal .refund-btn")
      |> render_click()

      Payments.process_refund_updated(
        system,
        %Stripe.Refund{
          id: refund_id,
          status: "failed",
          failure_reason: "lost_or_stolen_card"
        },
        nil
      )

      Notifications.wait_for_notifications()

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "Refund failed"
      assert invoice_box =~ "due to a lost or stolen card."

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "$69.00"
      assert invoice_box =~ "Refund failed"
      assert invoice_box =~ "due to a lost or stolen card."
    end

    test "refunding after release" do
      # TODO: Implement this
    end
  end

  describe "releasing an invoice" do
    test "successfully releasing invoice", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission
    } do
      amount = Money.new(42_000, :USD)
      tip = Money.new(6900, :USD)

      payment_fixture(artist, commission, amount, tip)

      client_conn = log_in_user(conn, client)
      artist_conn = log_in_user(conn, artist)

      {:ok, client_page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      {:ok, artist_page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      refute artist_page_live
             |> has_element?(".invoice-box .open-release-modal")

      client_page_live
      |> element(".invoice-box .open-release-modal")
      |> render_click()

      modal =
        client_page_live
        |> element(".invoice-box .release-modal.modal-open")
        |> render()

      assert modal =~ "Confirm Fund Release"
      assert modal =~ "Funds will be made available immediately"
      assert modal =~ ~r/<button[^<]+Confirm</

      client_page_live
      |> element(".invoice-box .release-modal .close-modal")
      |> render_click()

      refute client_page_live
             |> has_element?(".invoice-box .modal.modal-open")

      client_page_live
      |> element(".invoice-box .open-release-modal")
      |> render_click()

      client_page_live
      |> element(".invoice-box .modal .release-btn")
      |> render_click()

      refute client_page_live
             |> has_element?(".invoice-box .modal.modal-open")

      invoice_box =
        client_page_live
        |> element(".invoice-box")
        |> render()

      invoice_box =~ "Payment released to studio"

      invoice_box =
        artist_page_live
        |> element(".invoice-box")
        |> render()

      invoice_box =~ "Payment released to studio"
    end
  end
end
