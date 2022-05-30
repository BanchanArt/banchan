defmodule Banchan.CommissionsTest do
  @moduledoc """
  Tests for Commissions-related functionality.
  """
  use Banchan.DataCase

  import Banchan.AccountsFixtures
  import Banchan.CommissionsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Commissions
  alias Banchan.Notifications
  alias Banchan.Offerings

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
  end
end
