defmodule Banchan.CommissionsTest do
  @moduledoc """
  Tests for Commissions-related functionality.
  """
  use Banchan.DataCase

  import Banchan.AccountsFixtures
  import Banchan.CommissionsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Accounts
  alias Banchan.Commissions
  alias Banchan.Notifications

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
  end
end
