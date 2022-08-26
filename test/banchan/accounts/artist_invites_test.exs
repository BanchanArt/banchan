defmodule Banchan.AccountsTest.ArtistInvites do
  @moduledoc """
  Test for functionality related to artist invite tokens.
  """
  use Banchan.DataCase, async: true
  use Bamboo.Test

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.{ArtistToken, InviteRequest, User}

  describe "list_invite_requests/1" do
    test "lists all invite requests, in creation order" do
      {:ok, %InviteRequest{id: req1_id}} =
        Accounts.add_invite_request(
          "foo@example.com",
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-1000) |> NaiveDateTime.truncate(:second)
        )

      {:ok, %InviteRequest{id: req2_id}} =
        {:ok, req2} = Accounts.add_invite_request("foo2@example.com")

      {:ok, _} = Accounts.send_invite(Accounts.system_user(), req2, &extractable_user_token/1)

      assert [%InviteRequest{id: ^req1_id}, %InviteRequest{id: ^req2_id}] =
               Accounts.list_invite_requests().entries
    end

    test "supports an :unsent_only option to filter down to only requests that haven't been processed." do
      {:ok, %InviteRequest{id: req1_id}} =
        Accounts.add_invite_request(
          "foo@example.com",
          NaiveDateTime.utc_now() |> NaiveDateTime.add(-1000) |> NaiveDateTime.truncate(:second)
        )

      {:ok, req2} = Accounts.add_invite_request("foo2@example.com")

      {:ok, _} = Accounts.send_invite(Accounts.system_user(), req2, &extractable_user_token/1)

      assert [%InviteRequest{id: ^req1_id}] =
               Accounts.list_invite_requests(unsent_only: true).entries
    end
  end

  describe "add_artist_invites/2" do
    test "adds more invite slots to a user" do
      user = user_fixture()
      assert user.available_invites == 0

      {:ok, %User{available_invites: 5}} = Accounts.add_artist_invites(user, 5)

      assert %User{available_invites: 5} = Accounts.get_user(user.id)
    end

    test "handles nil available_invites" do
      user = user_fixture()

      Ecto.Query.from(u in User, where: u.id == ^user.id)
      |> Repo.update_all(set: [available_invites: nil])

      {:ok, %User{available_invites: 5}} = Accounts.add_artist_invites(user, 5)
    end
  end

  describe "send_invite_batch/3" do
    test "sends a batch of invite emails to the n oldest invite requests" do
      email = "foo@example.com"
      system = Accounts.system_user()

      {:ok, %InviteRequest{id: req1_id}} = Accounts.add_invite_request(email)
      {:ok, %InviteRequest{id: req2_id}} = Accounts.add_invite_request(email)
      {:ok, %InviteRequest{id: req3_id}} = Accounts.add_invite_request(email)
      {:ok, %InviteRequest{id: req4_id}} = Accounts.add_invite_request(email)

      assert {:ok,
              [%InviteRequest{id: ^req1_id, token_id: token_id_1}, %InviteRequest{id: ^req2_id}]} =
               Accounts.send_invite_batch(system, 2, &extractable_user_token/1)

      assert_delivered_email_matches(%{
        to: [{_, ^email}],
        subject: "You're invited to be an artist on Banchan Art!",
        text_body: text_body,
        html_body: html_body
      })

      assert %ArtistToken{id: ^token_id_1} =
               Accounts.get_artist_token(extract_user_token(text_body))

      assert %ArtistToken{id: ^token_id_1} =
               Accounts.get_artist_token(extract_user_token(html_body))

      assert_delivered_email_matches(%{
        to: [{_, ^email}],
        subject: "You're invited to be an artist on Banchan Art!"
      })

      assert [%InviteRequest{id: ^req3_id}, %InviteRequest{id: ^req4_id}] =
               Accounts.list_invite_requests(unsent_only: true).entries
    end
  end

  describe "send_invite/3" do
    test "System user can send an invite email" do
      email = "foo@example.com"
      system = Accounts.system_user()

      {:ok, %InviteRequest{id: request_id} = request} = Accounts.add_invite_request(email)

      assert {:ok, %InviteRequest{id: ^request_id, token_id: token_id}} =
               Accounts.send_invite(system, request, &extractable_user_token/1)

      assert_delivered_email_matches(%{
        to: [{_, ^email}],
        subject: "You're invited to be an artist on Banchan Art!",
        text_body: text_body,
        html_body: html_body
      })

      assert %ArtistToken{id: ^token_id} =
               Accounts.get_artist_token(extract_user_token(text_body))

      assert %ArtistToken{id: ^token_id} =
               Accounts.get_artist_token(extract_user_token(html_body))
    end

    test "regular users with enough invites can send an invite email" do
      email = "foo@example.com"
      user = user_fixture()

      {:ok, %InviteRequest{id: request_id} = request} = Accounts.add_invite_request(email)

      assert {:error, :no_invites} =
               Accounts.send_invite(user, request, &extractable_user_token/1)

      {:ok, user} = Accounts.add_artist_invites(user, 1)

      assert {:ok, %InviteRequest{id: ^request_id, token_id: token_id}} =
               Accounts.send_invite(user, request, &extractable_user_token/1)

      assert_delivered_email_matches(%{
        to: [{_, ^email}],
        subject: "You're invited to be an artist on Banchan Art!",
        text_body: text_body,
        html_body: html_body
      })

      assert %ArtistToken{id: ^token_id} =
               Accounts.get_artist_token(extract_user_token(text_body))

      assert %ArtistToken{id: ^token_id} =
               Accounts.get_artist_token(extract_user_token(html_body))

      # We're out of invites now
      {:ok, %InviteRequest{} = request} = Accounts.add_invite_request(email)

      assert {:error, :no_invites} =
               Accounts.send_invite(user, request, &extractable_user_token/1)

      assert %User{available_invites: 0} = Accounts.get_user(user.id)
    end
  end

  describe "add_invite_request" do
    test "inserts a new invite request" do
      email = "foo@example.com"

      assert {:ok, %InviteRequest{id: request_id, email: ^email, token_id: nil}} =
               Accounts.add_invite_request(email)

      assert [%InviteRequest{id: ^request_id}] = Accounts.list_invite_requests().entries
    end

    test "validates the email" do
      assert {:error, changeset} = Accounts.add_invite_request("badmail")

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "allows duplicates" do
      email = "foo@example.com"

      assert {:ok, %InviteRequest{id: request_id_1, email: ^email, token_id: nil}} =
               Accounts.add_invite_request(email)

      assert [%InviteRequest{id: ^request_id_1}] = Accounts.list_invite_requests().entries

      assert {:ok, %InviteRequest{id: request_id_2, email: ^email, token_id: nil}} =
               Accounts.add_invite_request(email)

      assert [%InviteRequest{id: ^request_id_1}, %InviteRequest{id: ^request_id_2}] =
               Accounts.list_invite_requests().entries
    end

    test "accepts an optional argument to specify a custom inserted_at timestamp" do
      timestamp =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.add(-1 * 60 * 60 * 24)
        |> NaiveDateTime.truncate(:second)

      assert {:ok, %InviteRequest{inserted_at: ^timestamp}} =
               Accounts.add_invite_request("foo@example.com", timestamp)

      assert [%InviteRequest{inserted_at: ^timestamp}] = Accounts.list_invite_requests().entries
    end
  end

  describe "get_invite_request/1" do
    test "gets an invite request by id" do
      {:ok, %InviteRequest{id: request_id}} = Accounts.add_invite_request("foo@example.com")

      assert %InviteRequest{id: ^request_id} = Accounts.get_invite_request(request_id)
    end

    test "returns nil if the invite request does not exist" do
      assert is_nil(Accounts.get_invite_request(123))
    end
  end

  describe "deliver_artist_invite_confirmation/1" do
    test "sends an email confirming that someone's signed up for the beta" do
      email = "foo@example.com"

      {:ok, %InviteRequest{} = request} = Accounts.add_invite_request("foo@example.com")

      assert {:ok, %Oban.Job{}} = Accounts.deliver_artist_invite_confirmation(request)

      assert_delivered_email_matches(%{
        to: [{_, ^email}],
        subject: "You're signed up for the Banchan Art artist beta!",
        text_body: text_body
      })

      assert text_body =~ "You've successfully signed up for the Banchan Art beta waiting list."
    end
  end

  describe "generate_artist_token/1" do
    test "system user can generate a new artist token regardless of invites" do
      system = Accounts.system_user()

      assert {:ok, %ArtistToken{id: token_id, token: token_string}} =
               Accounts.generate_artist_token(system)

      assert is_binary(token_string)

      assert %ArtistToken{id: ^token_id, token: ^token_string} =
               Accounts.get_artist_token(token_string)
    end

    test "regular users can generate tokens if they have enough invite slots" do
      user = user_fixture()

      assert {:error, :no_invites} = Accounts.generate_artist_token(user)

      {:ok, user} = Accounts.add_artist_invites(user, 1)

      assert {:ok, %ArtistToken{id: token_id, token: token_string}} =
               Accounts.generate_artist_token(user)

      assert %ArtistToken{id: ^token_id, token: ^token_string} =
               Accounts.get_artist_token(token_string)
    end
  end

  describe "get_artist_token/1" do
    test "fetches an existing artist token based on its token string" do
      {:ok, %ArtistToken{id: token_id, token: token_string}} =
        Accounts.generate_artist_token(Accounts.system_user())

      assert %ArtistToken{id: ^token_id} = Accounts.get_artist_token(token_string)
    end

    test "returns nil if the token doesn't exist" do
      refute Accounts.get_artist_token("not-a-token")
    end
  end

  describe "apply_artist_token/2" do
    test "adds the :artist role to a user" do
      %User{id: user_id} = user = user_fixture(%{roles: [:mod]})

      {:ok, %ArtistToken{id: token_id, token: token_string}} =
        Accounts.generate_artist_token(Accounts.system_user())

      assert {:ok, %ArtistToken{id: ^token_id, used_by_id: ^user_id}} =
               Accounts.apply_artist_token(user, token_string)

      assert %User{roles: [:artist, :mod]} = Accounts.get_user(user.id)
    end

    test "fails if the user is already an artist" do
      user = user_fixture(%{roles: [:artist]})

      assert {:error, :already_artist} = Accounts.apply_artist_token(user, "whatever")
    end

    test "fails if the the token does not exist" do
      user = user_fixture()

      assert {:error, :invalid_token} = Accounts.apply_artist_token(user, "whatever")
    end

    test "fails if the the token has already been used" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, %ArtistToken{token: token_string}} =
        Accounts.generate_artist_token(Accounts.system_user())

      {:ok, %ArtistToken{}} = Accounts.apply_artist_token(user1, token_string)

      assert {:error, :token_used} = Accounts.apply_artist_token(user2, token_string)
    end
  end
end
