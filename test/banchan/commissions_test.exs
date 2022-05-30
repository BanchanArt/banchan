defmodule Banchan.CommissionsTest do
  @moduledoc """
  Tests for Commissions-related functionality.
  """
  use Banchan.DataCase

  import Banchan.CommissionsFixtures

  alias Banchan.Accounts
  alias Banchan.Commissions

  describe "commissions" do
    test "get_commission!/2 returns the commission with given id" do
      commission = commission_fixture()

      assert Commissions.get_commission!(commission.public_id, commission.client).id ==
               commission.id

      assert_raise(Ecto.NoResultsError, fn ->
        {:ok, user} =
          Accounts.register_admin(%{
            handle: "another_admin",
            email: "another_test@example.com",
            password: "foobarbazquux",
            password_confirmation: "foobarbazquux"
          })

        Commissions.get_commission!(commission.public_id, user)
      end)
    end
  end
end
