defmodule Banchan.PaymentsTest.Expired do
  @moduledoc """
  Tests for the handling of expired invoices.
  """
  use Banchan.DataCase, async: true

  import Hammox

  import Banchan.CommissionsFixtures

  alias Banchan.Notifications
  alias Banchan.Payments
  alias Banchan.Payments.{Invoice, Payout}

  setup :verify_on_exit!

  setup do
    commission = commission_fixture()

    on_exit(fn -> Notifications.wait_for_notifications() end)

    %{
      commission: commission,
      client: commission.client,
      studio: commission.studio,
      artist: Enum.at(commission.studio.artists, 0),
      amount: Money.new(42_000, :USD),
      tip: Money.new(6900, :USD)
    }
  end

  describe "purge_expired_invoice/1" do
    test "ignores invoices that aren't either :succeeded or :released", %{
      artist: artist,
      commission: commission,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} =
        invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :)"
        })

      assert {:ok, %Invoice{id: ^invoice_id}} = Payments.purge_expired_invoice(invoice)
      invoice = Repo.reload(invoice)
      assert %Invoice{status: :pending} = invoice

      session = checkout_session_fixture(invoice, tip)
      assert {:ok, %Invoice{id: ^invoice_id}} = Payments.purge_expired_invoice(invoice)
      invoice = Repo.reload(invoice)
      assert %Invoice{status: :submitted} = invoice

      expire_mock_payment(session)
      assert {:ok, %Invoice{id: ^invoice_id}} = Payments.purge_expired_invoice(invoice)
      invoice = Repo.reload(invoice)
      assert %Invoice{status: :expired} = invoice
    end

    test "ignores refunds that aren't expired, even if :succeeded", %{
      artist: artist,
      commission: commission,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} =
        invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :x"
        })

      Oban.Testing.with_testing_mode(:manual, fn ->
        invoice
        |> checkout_session_fixture(tip)
        |> succeed_mock_payment!()
      end)

      assert {:ok, %Invoice{id: ^invoice_id, status: :succeeded, refund_status: nil}} =
               Payments.purge_expired_invoice(invoice)

      assert %Invoice{status: :succeeded, refund_status: nil} = Repo.reload(invoice)
    end

    test "initiates refunds for expired :succeeded invoices", %{
      client: client,
      artist: artist,
      commission: commission,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} =
        invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :x"
        })

      two_years_ago =
        DateTime.utc_now()
        |> DateTime.add(-1 * 60 * 60 * 24 * 365 * 2 - 1)

      Oban.Testing.with_testing_mode(:manual, fn ->
        invoice
        |> checkout_session_fixture(tip)
        |> succeed_mock_payment!(paid_on: two_years_ago)
      end)

      mock_refund_stripe_calls(invoice)

      Notifications.wait_for_notifications()
      Notifications.mark_all_as_read(client)
      Notifications.mark_all_as_read(artist)

      assert {:ok, %Invoice{id: ^invoice_id, status: :refunded, refund_status: :succeeded}} =
               Payments.purge_expired_invoice(invoice)

      assert %Invoice{status: :refunded, refund_status: :succeeded} = Repo.reload(invoice)

      Notifications.wait_for_notifications()

      assert [%_{type: "expired_invoice_refunded"}, _] =
               Notifications.unread_notifications(client).entries |> Enum.sort_by(& &1.id)

      assert [%_{type: "expired_invoice_refunded"}, _] =
               Notifications.unread_notifications(artist).entries |> Enum.sort_by(& &1.id)
    end

    test "Initiates a single-invoice payout for non-paid-out, expired :released invoices", %{
      artist: artist,
      client: client,
      commission: commission,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} =
        invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :x"
        })

      two_years_ago =
        DateTime.utc_now()
        |> DateTime.add(-1 * 60 * 60 * 24 * 365 * 2 - 1)

      Oban.Testing.with_testing_mode(:manual, fn ->
        invoice
        |> checkout_session_fixture(tip)
        |> succeed_mock_payment!(paid_on: two_years_ago)
      end)

      {:ok, _} = Payments.release_payment(client, commission, invoice)

      total_transferred = Repo.reload(invoice).total_transferred

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, fn _ ->
        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: total_transferred.amount
             }
           ],
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)
      |> expect(:create_payout, fn _, _ ->
        {:ok,
         %Stripe.Payout{
           id: stripe_payout_id,
           status: "pending",
           arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
           type: "card",
           method: "standard"
         }}
      end)

      Notifications.wait_for_notifications()
      Notifications.mark_all_as_read(client)
      Notifications.mark_all_as_read(artist)

      assert {:ok,
              %Invoice{
                id: ^invoice_id,
                status: :released,
                refund_status: nil,
                payout_available_on: payout_available_on
              }} = Payments.purge_expired_invoice(invoice)

      refute is_nil(payout_available_on)

      assert %Invoice{
               status: :released,
               refund_status: nil,
               payouts: payouts,
               payout_available_on: payout_available_on
             } = Repo.reload(invoice) |> Repo.preload(:payouts)

      refute is_nil(payout_available_on)
      assert [%Payout{status: :pending, amount: ^total_transferred}] = payouts

      Notifications.wait_for_notifications()

      assert [] = Notifications.unread_notifications(client).entries |> Enum.sort_by(& &1.id)

      assert [%_{type: "expired_invoice_paid_out"}, %_{type: "payout_sent"}] =
               Notifications.unread_notifications(artist).entries |> Enum.sort_by(& &1.id)
    end

    test "ignores :released invoices that are part of successful payouts", %{
      artist: artist,
      client: client,
      commission: commission,
      studio: studio,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} =
        invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :x"
        })

      two_years_ago =
        DateTime.utc_now()
        |> DateTime.add(-1 * 60 * 60 * 24 * 365 * 2 - 1)

      Oban.Testing.with_testing_mode(:manual, fn ->
        invoice
        |> checkout_session_fixture(tip)
        |> succeed_mock_payment!(paid_on: two_years_ago)
      end)

      {:ok, _} = Payments.release_payment(client, commission, invoice)

      total_transferred = Repo.reload(invoice).total_transferred

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, fn _ ->
        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: total_transferred.amount
             }
           ],
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)
      |> expect(:retrieve_charge, fn _ ->
        {:ok,
         %Stripe.Charge{
           balance_transaction: %Stripe.BalanceTransaction{
             status: "available"
           }
         }}
      end)
      |> expect(:create_payout, fn _, _ ->
        {:ok,
         %Stripe.Payout{
           id: stripe_payout_id,
           status: "pending",
           arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
           type: "card",
           method: "standard"
         }}
      end)

      {:ok, _} = Payments.payout_studio(artist, studio)

      Payments.process_payout_updated!(%Stripe.Payout{
        id: stripe_payout_id,
        status: "paid",
        arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
        type: "card",
        method: "standard"
      })

      assert %Invoice{
               status: :released,
               refund_status: nil,
               payouts: payouts
             } = Repo.reload(invoice) |> Repo.preload(:payouts)

      assert [
               %Payout{
                 id: payout_id,
                 stripe_payout_id: ^stripe_payout_id,
                 status: :paid,
                 amount: ^total_transferred
               }
             ] = payouts

      assert {:ok,
              %Invoice{
                id: ^invoice_id,
                status: :released,
                refund_status: nil
              }} = Payments.purge_expired_invoice(invoice)

      assert %Invoice{
               status: :released,
               refund_status: nil,
               payouts: payouts
             } = Repo.reload(invoice) |> Repo.preload(:payouts)

      assert [%Payout{id: ^payout_id, status: :paid, amount: ^total_transferred}] = payouts
    end

    test "defers action on :released invoices that are in a pending payout", %{
      artist: artist,
      client: client,
      commission: commission,
      studio: studio,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} =
        invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :x"
        })

      two_years_ago =
        DateTime.utc_now()
        |> DateTime.add(-1 * 60 * 60 * 24 * 365 * 2 - 1)

      Oban.Testing.with_testing_mode(:manual, fn ->
        invoice
        |> checkout_session_fixture(tip)
        |> succeed_mock_payment!(paid_on: two_years_ago)

        # The notificatifier will fail, but that's fine. We just want to clear the queue.
        assert %{success: 1, failure: 1} =
                 Oban.drain_queue(
                   queue: :invoice_purge,
                   with_scheduled: true
                 )
      end)

      {:ok, _} = Payments.release_payment(client, commission, invoice)

      total_transferred = Repo.reload(invoice).total_transferred

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, fn _ ->
        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: total_transferred.amount
             }
           ],
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)
      |> expect(:retrieve_charge, fn _ ->
        {:ok,
         %Stripe.Charge{
           balance_transaction: %Stripe.BalanceTransaction{
             status: "available"
           }
         }}
      end)
      |> expect(:create_payout, fn _, _ ->
        {:ok,
         %Stripe.Payout{
           id: stripe_payout_id,
           status: "pending",
           arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
           type: "card",
           method: "standard"
         }}
      end)

      {:ok, _} = Payments.payout_studio(artist, studio)

      Oban.Testing.with_testing_mode(:manual, fn ->
        refute_enqueued(worker: ExpiredInvoicePurger, args: %{invoice_id: invoice_id})

        assert {:ok,
                %Invoice{
                  id: ^invoice_id,
                  status: :released,
                  refund_status: nil
                }} = Payments.purge_expired_invoice(invoice)

        assert %{success: 1, failure: 0} =
                 Oban.drain_queue(
                   queue: :invoice_purge,
                   with_scheduled: true
                 )
      end)
    end
  end
end
