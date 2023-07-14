defmodule Banchan.AccountsTest.Deletion do
  @moduledoc """
  Tests for functionality related to user deactivation and pruning/deletion.
  """
  use Banchan.DataCase, async: true

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Repo

  describe "reactivate_user/2" do
    test "reactivates a previously deactivated user" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      {:ok, _} = Accounts.deactivate_user(user, user, valid_user_password())

      assert {:ok, %User{id: ^user_id, deactivated_at: nil}} =
               Accounts.reactivate_user(user, user)
    end

    test "admins can reactivate users" do
      admin = unconfirmed_user_fixture(%{roles: [:admin]})
      %User{id: user_id} = user = unconfirmed_user_fixture()

      {:ok, _} = Accounts.deactivate_user(user, user, valid_user_password())

      assert {:ok, %User{id: ^user_id, deactivated_at: nil}} =
               Accounts.reactivate_user(admin, user)
    end

    test "fails if the actor is not the user themself, or is not an admin" do
      mod = unconfirmed_user_fixture(%{roles: [:mod]})
      rando = unconfirmed_user_fixture()
      user = unconfirmed_user_fixture()

      {:ok, _} = Accounts.deactivate_user(user, user, valid_user_password())

      assert {:error, :unauthorized} = Accounts.reactivate_user(mod, user)
      assert {:error, :unauthorized} = Accounts.reactivate_user(rando, user)
    end
  end

  describe "deactivate_user/3" do
    test "marks the user as deactivated and sets the deactivation time" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      assert {:ok, %User{id: ^user_id, deactivated_at: deactivated_at}} =
               Accounts.deactivate_user(user, user, valid_user_password())

      diff =
        deactivated_at
        |> NaiveDateTime.diff(NaiveDateTime.utc_now())
        |> abs()

      assert diff < 10
    end

    test "admins can deactivate users" do
      admin = unconfirmed_user_fixture(%{roles: [:admin]})
      %User{id: mod_id} = mod = unconfirmed_user_fixture(%{roles: [:mod]})
      %User{id: user_id} = user = unconfirmed_user_fixture()

      assert {:ok, %User{id: ^user_id, deactivated_at: %NaiveDateTime{}}} =
               Accounts.deactivate_user(admin, user, nil)

      assert {:ok, %User{id: ^mod_id, deactivated_at: %NaiveDateTime{}}} =
               Accounts.deactivate_user(admin, mod, nil)
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

      assert {:error, :unauthorized} =
               Accounts.deactivate_user(stranger, user, valid_user_password())

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

      assert {:ok, %User{id: ^user_id}} =
               Accounts.deactivate_user(user, user, valid_user_password())

      refute Accounts.get_user_by_session_token(token1)
      refute Accounts.get_user_by_session_token(token2)
    end

    test "does not require password for OAuth users" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      [
        %{provider: "discord", attrs: [discord_uid: "discord-user-id"]},
        %{provider: "google", attrs: [google_uid: "google-user-id"]}
      ]
      |> Enum.each(fn test_variant ->
        {1, _} =
          Repo.update_all(Ecto.Query.from(u in User, where: u.id == ^user.id),
            set: test_variant[:attrs]
          )

        assert {:ok, %User{id: ^user_id, deactivated_at: %NaiveDateTime{}}} =
                 Accounts.deactivate_user(user, user, nil)
      end)
    end
  end

  describe "prune_users/0" do
    test "deletes deactivated users that have been deactivated 30 days or longer" do
      user1 = unconfirmed_user_fixture()
      %User{id: user2_id} = user2 = unconfirmed_user_fixture()

      {:ok, _} = Accounts.deactivate_user(user1, user1, valid_user_password())
      {:ok, _} = Accounts.deactivate_user(user2, user2, valid_user_password())

      month_ago =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(60 * 60 * 24 * 30 * -1 - 10)
        |> NaiveDateTime.truncate(:second)

      {1, _} =
        Ecto.Query.from(u in User, where: u.id == ^user1.id)
        |> Repo.update_all(set: [deactivated_at: month_ago])

      assert {:ok, 1} = Accounts.prune_users()

      %User{id: system_id} = Accounts.system_user()

      assert [%User{id: ^system_id}, %User{id: ^user2_id}] =
               Repo.all(User) |> Enum.sort_by(& &1.id)
    end

    test "does not delete active users" do
      user = unconfirmed_user_fixture()

      assert {:ok, 0} = Accounts.prune_users()

      assert Accounts.get_user(user.id)
    end
  end
end
