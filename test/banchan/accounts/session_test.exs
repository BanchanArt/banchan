defmodule Banchan.AccountsTest.Session do
  @moduledoc """
  Tests for functionality related to user sessions.
  """
  use Banchan.DataCase, async: true

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.{User, UserToken}

  alias BanchanWeb.UserAuth

  describe "generate_user_session_token/1" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: unconfirmed_user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = unconfirmed_user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = unconfirmed_user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "logout_user/1" do
    test "clears all sessions for a user" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      token1 = Accounts.generate_user_session_token(user)
      token2 = Accounts.generate_user_session_token(user)

      assert {:ok, %User{id: ^user_id}} = Accounts.logout_user(user)

      refute Accounts.get_user_by_session_token(token1)
      refute Accounts.get_user_by_session_token(token2)
    end
  end

  describe "subscribe_to_auth_events/0" do
    test "subscribes to logout events" do
      %User{id: user_id} = user = unconfirmed_user_fixture()
      topic = UserAuth.pubsub_topic()

      Accounts.generate_user_session_token(user)
      {:ok, _} = Accounts.logout_user(user)

      refute_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "logout_user"
      }

      assert :ok = Accounts.subscribe_to_auth_events()

      # Process that does the logout doesn't get the broadcast.
      Accounts.generate_user_session_token(user)

      {:ok, _} = Accounts.logout_user(user)

      refute_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "logout_user"
      }

      # But other processes do.
      Accounts.generate_user_session_token(user)

      {:ok, %User{}} = Task.await(Task.async(fn -> Accounts.logout_user(user) end))

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "logout_user",
        payload: %{
          user: %User{id: ^user_id}
        }
      }
    end
  end
end
