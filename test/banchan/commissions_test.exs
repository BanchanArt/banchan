defmodule Banchan.CommissionsTest do
  @moduledoc """
  Tests for Commissions-related functionality.
  """
  use Banchan.DataCase

  import Mox

  import Banchan.AccountsFixtures
  import Banchan.CommissionsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Commissions
  alias Banchan.Notifications
  alias Banchan.Offerings

  setup :verify_on_exit!

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
          |> Notifications.commission_subscribers()
          |> Enum.map(& &1.id)

        assert subscribers == [user.id]
      end)

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

    test "invoice" do
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

        assert Money.multiply(Money.add(amount, tip), studio.platform_fee).amount ==
                 sess.payment_intent_data.application_fee_amount

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

      assert checkout_uri ==
               Commissions.process_payment!(
                 user,
                 invoice.event |> Repo.reload() |> Repo.preload(:invoice),
                 commission,
                 uri,
                 tip
               )
    end
  end
end
