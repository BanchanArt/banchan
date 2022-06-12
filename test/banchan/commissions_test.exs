defmodule Banchan.CommissionsTest do
  @moduledoc """
  Tests for Commissions-related functionality.
  """
  use Banchan.DataCase, async: true

  import ExUnit.CaptureLog
  import Mox

  import Banchan.AccountsFixtures
  import Banchan.CommissionsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Commissions
  alias Banchan.Commissions.{Event, Invoice}
  alias Banchan.Notifications
  alias Banchan.Offerings

  setup :verify_on_exit!

  setup do
    on_exit(fn -> Notifications.wait_for_notifications() end)
  end

  describe "commissions" do
    test "get_commission!/2 returns the commission with given id" do
      commission = commission_fixture()

      assert Commissions.get_commission!(commission.public_id, commission.client).id ==
               commission.id

      assert_raise(Ecto.NoResultsError, fn ->
        Commissions.get_commission!(commission.public_id, user_fixture())
      end)
    end

    test "basic creation" do
      user = user_fixture()
      studio = studio_fixture([user])
      offering = offering_fixture(studio)

      Commissions.subscribe_to_new_commissions()

      {:ok, commission} =
        Commissions.create_commission(
          user,
          studio,
          offering,
          [],
          [],
          %{
            title: "some title",
            description: "Some Description",
            tos_ok: true
          }
        )

      assert "some title" == commission.title
      assert "Some Description" == commission.description
      assert commission.tos_ok

      Repo.transaction(fn ->
        subscribers =
          commission
          |> Commissions.Notifications.subscribers()
          |> Enum.map(& &1.id)

        assert subscribers == [user.id]
      end)

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: "commission",
        event: "new_commission",
        payload: ^commission
      }

      Commissions.unsubscribe_from_new_commissions()
    end

    test "available_slots" do
      user = user_fixture()
      studio = studio_fixture([user])
      offering = offering_fixture(studio)

      new_comm = fn ->
        Commissions.create_commission(
          user,
          studio,
          offering,
          [],
          [],
          %{
            title: "some title",
            description: "Some Description",
            tos_ok: true
          }
        )
      end

      {:ok, offering} =
        Offerings.update_offering(offering, true, %{
          slots: 1
        })

      {:ok, comm1} = new_comm.()
      {:ok, comm2} = new_comm.()

      {:ok, _comm1} = Commissions.update_status(user, comm1, :accepted)

      assert {:error, :no_slots_available} == new_comm.()

      {:ok, _offering} =
        Offerings.update_offering(offering, true, %{
          slots: 2
        })

      {:ok, _comm2} = Commissions.update_status(user, comm2, :accepted)

      assert {:error, :no_slots_available} == new_comm.()

      {:ok, _comm1} = Commissions.update_status(user, comm1 |> Repo.reload(), :ready_for_review)
      {:ok, _comm1} = Commissions.update_status(user, comm1 |> Repo.reload(), :approved)

      {:ok, comm3} = new_comm.()
      {:ok, _comm3} = Commissions.update_status(user, comm3, :accepted)
      assert {:error, :no_slots_available} == new_comm.()
    end
  end

  describe "invoices" do
    test "basic invoice" do
      commission = commission_fixture()
      amount = Money.new(420, :USD)

      {:ok, invoice} =
        Commissions.invoice(commission.client, commission, true, [], %{
          "amount" => amount,
          "text" => "Please pay me?"
        })

      assert commission.client_id == invoice.client_id
      assert amount == invoice.amount
      assert amount == invoice.event.amount
      assert "Please pay me?" == invoice.event.text
      assert :comment == invoice.event.type
    end

    test "process payment" do
      commission = commission_fixture()
      user = commission.client
      studio = commission.studio
      uri = "https://come.back.here"
      checkout_uri = "https://checkout.url"
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)
      fee = Money.multiply(Money.add(amount, tip), studio.platform_fee)

      invoice =
        invoice_fixture(user, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      Banchan.StripeAPI.Mock
      |> expect(:create_session, fn sess ->
        assert ["card"] == sess.payment_method_types
        assert "payment" == sess.mode
        assert uri == sess.cancel_url
        assert uri == sess.success_url

        assert fee.amount == sess.payment_intent_data.application_fee_amount

        assert studio.stripe_id == sess.payment_intent_data.transfer_data.destination

        assert [
                 %{
                   name: "Commission Invoice Payment",
                   quantity: 1,
                   amount: amount.amount,
                   currency: "usd"
                 },
                 %{
                   name: "Extra Tip",
                   quantity: 1,
                   amount: tip.amount,
                   currency: "usd"
                 }
               ] == sess.line_items

        {:ok,
         %Stripe.Session{
           id: "stripe-mock-session-id#{System.unique_integer()}",
           url: checkout_uri
         }}
      end)

      event = invoice.event |> Repo.reload() |> Repo.preload(:invoice)

      assert checkout_uri ==
               Commissions.process_payment!(
                 user,
                 event,
                 commission,
                 uri,
                 tip
               )
    end

    test "process payment succeeded" do
      commission = commission_fixture()
      user = commission.client
      uri = "https://come.back.here"
      checkout_uri = "https://checkout.url"
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(user, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess_id = "stripe-mock-session-id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:create_session, fn _sess ->
        {:ok,
         %Stripe.Session{
           id: sess_id,
           url: checkout_uri
         }}
      end)

      event = invoice.event |> Repo.reload() |> Repo.preload(:invoice)

      assert checkout_uri ==
               Commissions.process_payment!(
                 user,
                 event,
                 commission,
                 uri,
                 tip
               )

      # Let's just make it so it's available immediately.
      available_on = DateTime.add(DateTime.utc_now(), -2)

      txn_id = "stripe-mock-txn-id#{System.unique_integer()}"
      payment_intent_id = "stripe-mock-payment-intent-id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_payment_intent, fn id, _, _ ->
        assert payment_intent_id == id
        {:ok, %{charges: %{data: [%{balance_transaction: txn_id}]}}}
      end)
      |> expect(:retrieve_balance_transaction, fn id, _ ->
        assert txn_id == id

        {:ok,
         %{
           available_on: DateTime.to_unix(available_on),
           amount: Money.add(amount, tip).amount,
           currency: "usd"
         }}
      end)

      Commissions.subscribe_to_commission_events(commission)

      assert :ok ==
               Commissions.process_payment_succeeded!(%Stripe.Session{
                 id: sess_id,
                 payment_intent: payment_intent_id
               })

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert DateTime.to_unix(available_on) == DateTime.to_unix(invoice.payout_available_on)
      assert :succeeded == invoice.status

      commission = commission |> Repo.reload() |> Repo.preload(:events)

      processed_event = Enum.find(commission.events, &(&1.type == :payment_processed))

      assert processed_event
      assert processed_event.commission_id == commission.id
      assert processed_event.actor_id == user.id
      assert processed_event.amount == Money.add(amount, tip)

      eid = processed_event.id

      topic = "commission:#{commission.public_id}"

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "new_events",
        payload: [%Event{type: :payment_processed, id: ^eid}]
      }

      invoice_event = invoice.event |> Repo.reload()
      iid = invoice_event.id

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{type: :comment, id: ^iid, invoice: %Invoice{status: :succeeded}}
      }

      assert_raise RuntimeError, fn ->
        Commissions.expire_payment!(invoice, true)
      end
    end

    test "process payment expired" do
      commission = commission_fixture()
      user = commission.client

      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(user, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess = checkout_session_fixture(invoice, tip)

      Commissions.subscribe_to_commission_events(commission)

      Commissions.process_payment_expired!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert :expired == invoice.status

      topic = "commission:#{commission.public_id}"
      iid = invoice.event.id

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{type: :comment, id: ^iid, invoice: %Invoice{status: :expired}}
      }

      assert_raise RuntimeError, fn ->
        Commissions.expire_payment!(invoice, true)
      end
    end

    test "manually expire already-started payment" do
      commission = commission_fixture()
      user = commission.client

      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(user, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess = checkout_session_fixture(invoice, tip)
      invoice = invoice |> Repo.reload()

      Commissions.subscribe_to_commission_events(commission)

      assert {:error, :unauthorized} == Commissions.expire_payment!(invoice, false)

      Banchan.StripeAPI.Mock
      |> expect(:expire_payment, fn sess_id ->
        assert sess_id == sess.id
        :ok
      end)

      assert :ok == Commissions.expire_payment!(invoice, true)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      # Manual payment expiry relies on Stripe hitting our webhook after the fact

      assert :submitted == invoice.status

      topic = "commission:#{commission.public_id}"
      iid = invoice.event.id

      refute_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{type: :comment, id: ^iid, invoice: %Invoice{status: :expired}}
      }
    end

    test "manually expire pending payment" do
      commission = commission_fixture()
      user = commission.client

      amount = Money.new(420, :USD)

      invoice =
        invoice_fixture(user, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      invoice = invoice |> Repo.reload()

      Commissions.subscribe_to_commission_events(commission)

      assert {:error, :unauthorized} == Commissions.expire_payment!(invoice, false)
      assert :ok == Commissions.expire_payment!(invoice, true)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert :expired == invoice.status

      topic = "commission:#{commission.public_id}"
      iid = invoice.event.id

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{type: :comment, id: ^iid, invoice: %Invoice{status: :expired}}
      }

      assert_raise RuntimeError, fn ->
        Commissions.expire_payment!(invoice, true)
      end
    end

    test "release payment without approving commission" do
      commission = commission_fixture()
      studio = commission.studio
      client = commission.client
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      Commissions.subscribe_to_commission_events(commission)
      topic = "commission:#{commission.public_id}"

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)
      iid = invoice.id
      eid = invoice.event.id

      assert_raise MatchError, fn ->
        Commissions.release_payment!(artist, commission, invoice)
      end

      invoice = invoice |> Repo.reload()

      # No change to status.
      assert :succeeded == invoice.status

      Notifications.wait_for_notifications()

      refute_received %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{type: :comment, id: ^eid, invoice: %Invoice{id: ^iid, status: :released}}
      }

      Commissions.release_payment!(client, commission, invoice)

      invoice = invoice |> Repo.reload()

      assert :released == invoice.status

      Notifications.wait_for_notifications()

      assert_received %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{type: :comment, id: ^eid, invoice: %Invoice{id: ^iid, status: :released}}
      }

      # Can't re-release once it's been released.
      assert_raise MatchError, fn ->
        Commissions.release_payment!(artist, commission, invoice)
      end
    end

    test "refund payment before approval - success" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      Commissions.subscribe_to_commission_events(commission)
      topic = "commission:#{commission.public_id}"

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert {:error, :unauthorized} == Commissions.refund_payment(artist, invoice, false)

      charge_id = "stripe-mock-charge-id#{System.unique_integer()}"
      refund_id = "stripe-mock-refund-id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn sid, _opts ->
        assert sess.id == sid
        {:ok, sess}
      end)
      |> expect(:retrieve_payment_intent, fn intent_id, _params, _opts ->
        assert sess.payment_intent == intent_id

        {:ok,
         %Stripe.PaymentIntent{
           id: intent_id,
           charges: %{
             data: [
               %{id: charge_id}
             ]
           }
         }}
      end)
      |> expect(:create_refund, fn params, _opts ->
        assert charge_id == params.charge
        assert true == params.reverse_transfer
        assert true == params.refund_application_fee
        {:ok, %Stripe.Refund{id: refund_id, status: "succeeded"}}
      end)

      iid = invoice.id
      artist_id = artist.id

      assert {:ok,
              %Invoice{
                id: ^iid,
                stripe_refund_id: ^refund_id,
                status: :refunded,
                refund_status: :succeeded,
                refunded_by_id: ^artist_id
              }} = Commissions.refund_payment(artist, invoice, true)

      eid = invoice.event.id

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :refunded}
        }
      }
    end

    test "refund payment before approval - refund api request failed" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert {:error, :unauthorized} == Commissions.refund_payment(artist, invoice, false)

      charge_id = "stripe-mock-charge-id#{System.unique_integer()}"

      err = %Stripe.Error{
        source: "test",
        code: "badness",
        message: "bad request"
      }

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn sid, _opts ->
        assert sess.id == sid
        {:ok, sess}
      end)
      |> expect(:retrieve_payment_intent, fn intent_id, _params, _opts ->
        assert sess.payment_intent == intent_id

        {:ok,
         %Stripe.PaymentIntent{
           id: intent_id,
           charges: %{
             data: [
               %{id: charge_id}
             ]
           }
         }}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:error, err}
      end)

      log =
        capture_log([level: :error], fn ->
          assert {:error, ^err} = Commissions.refund_payment(artist, invoice, true)
        end)

      assert log =~ "bad request"
    end

    test "refund payment before approval - refund failed" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert {:error, :unauthorized} == Commissions.refund_payment(artist, invoice, false)

      refund_id = "stripe-mock-refund-id#{System.unique_integer()}"
      charge_id = "stripe-mock-charge-id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn sid, _opts ->
        assert sess.id == sid
        {:ok, sess}
      end)
      |> expect(:retrieve_payment_intent, fn intent_id, _params, _opts ->
        assert sess.payment_intent == intent_id

        {:ok,
         %Stripe.PaymentIntent{
           id: intent_id,
           charges: %{
             data: [
               %{id: charge_id}
             ]
           }
         }}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:ok, %Stripe.Refund{id: refund_id, status: "failed", failure_reason: "unknown"}}
      end)

      Commissions.subscribe_to_commission_events(commission)
      topic = "commission:#{commission.public_id}"

      iid = invoice.id
      eid = invoice.event.id

      log =
        capture_log([level: :error], fn ->
          assert {:ok,
                  %Invoice{
                    id: ^iid,
                    refund_status: :failed,
                    refund_failure_reason: :unknown,
                    status: :succeeded
                  }} = Commissions.refund_payment(artist, invoice, true)
        end)

      assert log =~ "unknown"

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{
            status: :succeeded,
            refund_status: :failed,
            refund_failure_reason: :unknown
          }
        }
      }

      invoice = invoice |> Repo.reload()

      assert %Invoice{
               id: ^iid,
               refund_status: :failed,
               refund_failure_reason: :unknown,
               status: :succeeded
             } = invoice

      refund = %Stripe.Refund{id: refund_id, status: "succeeded"}

      assert {:ok,
              %Invoice{
                id: ^iid,
                stripe_refund_id: ^refund_id,
                refund_status: :succeeded,
                refund_failure_reason: nil,
                status: :refunded
              }} = Commissions.process_refund_updated(refund, nil)

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :refunded, refund_status: :succeeded}
        }
      }
    end

    test "refund payment before approval - refund pending" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert {:error, :unauthorized} == Commissions.refund_payment(artist, invoice, false)

      refund_id = "stripe-mock-refund-id#{System.unique_integer()}"
      charge_id = "stripe-mock-charge-id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn sid, _opts ->
        assert sess.id == sid
        {:ok, sess}
      end)
      |> expect(:retrieve_payment_intent, fn intent_id, _params, _opts ->
        assert sess.payment_intent == intent_id

        {:ok,
         %Stripe.PaymentIntent{
           id: intent_id,
           charges: %{
             data: [
               %{id: charge_id}
             ]
           }
         }}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:ok, %Stripe.Refund{id: refund_id, status: "pending"}}
      end)

      Commissions.subscribe_to_commission_events(commission)
      topic = "commission:#{commission.public_id}"

      iid = invoice.id
      eid = invoice.event.id

      assert {:ok,
              %Invoice{
                id: ^iid,
                stripe_refund_id: ^refund_id,
                refund_status: :pending,
                status: :succeeded
              }} = Commissions.refund_payment(artist, invoice, true)

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :succeeded, refund_status: :pending}
        }
      }

      invoice = invoice |> Repo.reload()

      assert %Invoice{id: ^iid, refund_status: :pending, status: :succeeded} = invoice

      refund = %Stripe.Refund{id: refund_id, status: "succeeded"}

      assert {:ok,
              %Invoice{
                id: ^iid,
                stripe_refund_id: ^refund_id,
                refund_status: :succeeded,
                refund_failure_reason: nil,
                status: :refunded
              }} = Commissions.process_refund_updated(refund, nil)

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :refunded, refund_status: :succeeded}
        }
      }
    end

    test "refund payment before approval - refund requires action" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert {:error, :unauthorized} == Commissions.refund_payment(artist, invoice, false)

      refund_id = "stripe-mock-refund-id#{System.unique_integer()}"
      charge_id = "stripe-mock-charge-id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn sid, _opts ->
        assert sess.id == sid
        {:ok, sess}
      end)
      |> expect(:retrieve_payment_intent, fn intent_id, _params, _opts ->
        assert sess.payment_intent == intent_id

        {:ok,
         %Stripe.PaymentIntent{
           id: intent_id,
           charges: %{
             data: [
               %{id: charge_id}
             ]
           }
         }}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:ok, %Stripe.Refund{id: refund_id, status: "requires_action"}}
      end)

      Commissions.subscribe_to_commission_events(commission)
      topic = "commission:#{commission.public_id}"

      iid = invoice.id
      eid = invoice.event.id

      assert {:ok,
              %Invoice{
                id: ^iid,
                stripe_refund_id: ^refund_id,
                refund_status: :requires_action,
                status: :succeeded
              }} = Commissions.refund_payment(artist, invoice, true)

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :succeeded, refund_status: :requires_action}
        }
      }

      invoice = invoice |> Repo.reload()

      assert %Invoice{id: ^iid, refund_status: :requires_action, status: :succeeded} = invoice

      refund = %Stripe.Refund{id: refund_id, status: "succeeded"}

      assert {:ok,
              %Invoice{
                id: ^iid,
                stripe_refund_id: ^refund_id,
                refund_status: :succeeded,
                refund_failure_reason: nil,
                status: :refunded
              }} = Commissions.process_refund_updated(refund, nil)

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :refunded, refund_status: :succeeded}
        }
      }
    end

    test "refund payment before approval - refund canceled" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Send help."
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice = invoice |> Repo.reload() |> Repo.preload(:event)

      assert {:error, :unauthorized} == Commissions.refund_payment(artist, invoice, false)

      refund_id = "stripe-mock-refund-id#{System.unique_integer()}"
      charge_id = "stripe-mock-charge-id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_session, fn sid, _opts ->
        assert sess.id == sid
        {:ok, sess}
      end)
      |> expect(:retrieve_payment_intent, fn intent_id, _params, _opts ->
        assert sess.payment_intent == intent_id

        {:ok,
         %Stripe.PaymentIntent{
           id: intent_id,
           charges: %{
             data: [
               %{id: charge_id}
             ]
           }
         }}
      end)
      |> expect(:create_refund, fn _params, _opts ->
        {:ok, %Stripe.Refund{id: refund_id, status: "canceled"}}
      end)

      Commissions.subscribe_to_commission_events(commission)
      topic = "commission:#{commission.public_id}"

      iid = invoice.id
      eid = invoice.event.id

      log =
        capture_log([level: :error], fn ->
          assert {:ok,
                  %Invoice{
                    id: ^iid,
                    stripe_refund_id: ^refund_id,
                    refund_status: :canceled,
                    status: :succeeded
                  }} = Commissions.refund_payment(artist, invoice, true)
        end)

      assert log =~ "canceled"

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :succeeded, refund_status: :canceled}
        }
      }

      invoice = invoice |> Repo.reload()

      assert %Invoice{id: ^iid, refund_status: :canceled, status: :succeeded} = invoice

      refund = %Stripe.Refund{id: refund_id, status: "succeeded"}

      assert {:ok,
              %Invoice{
                id: ^iid,
                stripe_refund_id: ^refund_id,
                refund_status: :succeeded,
                refund_failure_reason: nil,
                status: :refunded
              }} = Commissions.process_refund_updated(refund, nil)

      Notifications.wait_for_notifications()

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "event_updated",
        payload: %Event{
          type: :comment,
          id: ^eid,
          invoice: %Invoice{status: :refunded, refund_status: :succeeded}
        }
      }
    end

    test "refund payment after approval" do
    end
  end
end
