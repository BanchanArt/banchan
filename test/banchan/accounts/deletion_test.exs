defmodule Banchan.AccountsTest.Deletion do
  @moduledoc """
  Tests for functionality related to user deactivation and pruning/deletion.
  """
  use Banchan.DataCase, async: true

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Repo

  # describe "reactivate_user/2" do
  #   test ""
  # end

  describe "deactivate_user/3" do
    test "marks the user as deactivated and sets the deactivation time" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      assert {:ok, %User{id: ^user_id, deactivated_at: deactivated_at}} = Accounts.deactivate_user(user, user, valid_user_password())

      diff = deactivated_at
      |> NaiveDateTime.diff(NaiveDateTime.utc_now())
      |> abs()

      assert diff < 10
    end

    test "admins can deactivate users" do
      admin = unconfirmed_user_fixture(%{roles: [:admin]})
      %User{id: mod_id} = mod = unconfirmed_user_fixture(%{roles: [:mod]})
      %User{id: user_id} = user = unconfirmed_user_fixture()

      assert {:ok, %User{id: ^user_id, deactivated_at: %NaiveDateTime{}}} = Accounts.deactivate_user(admin, user, nil)
      assert {:ok, %User{id: ^mod_id, deactivated_at: %NaiveDateTime{}}} = Accounts.deactivate_user(admin, mod, nil)
    end

    test "fails if the password is invalid" do
      user = unconfirmed_user_fixture()

      assert {:error, changeset} = Accounts.deactivate_user(user, user, "badpass")

      assert %{
        current_password: ["is not valid"]
      } = errors_on(changeset)
    end

    test "fails if the actor is not either the user themself or an admin" do
      mod = unconfirmed_user_fixture(%{roles: [:mod]})
      user = unconfirmed_user_fixture()
      stranger = unconfirmed_user_fixture()

      assert {:error, :unauthorized} = Accounts.deactivate_user(stranger, user, valid_user_password())
      assert {:error, :unauthorized} = Accounts.deactivate_user(mod, user, valid_user_password())
    end

    test "admins can't deactivate each other" do
      admin = unconfirmed_user_fixture(%{roles: [:admin]})
      admin2 = unconfirmed_user_fixture(%{roles: [:admin]})

      assert {:error, :unauthorized} = Accounts.deactivate_user(admin, admin2, nil)
    end

    test "logs out the user from its current sessions" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      token1 = Accounts.generate_user_session_token(user)
      token2 = Accounts.generate_user_session_token(user)

      assert {:ok, %User{id: ^user_id}} = Accounts.deactivate_user(user, user, valid_user_password())

      refute Accounts.get_user_by_session_token(token1)
      refute Accounts.get_user_by_session_token(token2)
    end

    test "does not require password for OAuth email-less users" do
      %User{id: user_id} = user = unconfirmed_user_fixture()
      {1, _} = Repo.update_all(Ecto.Query.from(u in User, where: u.id == ^user.id), set: [email: nil])

      assert {:ok, %User{id: ^user_id, deactivated_at: %NaiveDateTime{}}} = Accounts.deactivate_user(user, user, nil)
    end
  end

  # @tag skip: "TODO"
  # describe "prune_users/0" do
  # end
end
