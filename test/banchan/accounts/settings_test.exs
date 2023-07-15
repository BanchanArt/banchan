defmodule Banchan.AccountsTest.Settings do
  @moduledoc """
  Tests for functionality related to user settings and profile management.
  """
  use Banchan.DataCase, async: true

  use Bamboo.Test

  alias Banchan.Accounts
  import Banchan.AccountsFixtures
  alias Banchan.Accounts.{User, UserToken}

  describe "change_user_handle/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = Accounts.change_user_handle(%User{})
    end

    test "allows handle to be set" do
      changeset =
        Accounts.change_user_handle(%User{}, %{
          "handle" => "newhandle"
        })

      assert changeset.valid?
      assert get_change(changeset, :handle) == "newhandle"
    end
  end

  describe "update_admin_fields/3" do
    test "updates moderation notes and roles" do
      admin = user_fixture(%{roles: [:admin]})
      %User{id: user_id} = user = user_fixture()

      assert {:ok,
              %User{
                id: ^user_id,
                moderation_notes: "did a bad",
                roles: [:artist]
              }} =
               Accounts.update_admin_fields(admin, user, %{
                 "moderation_notes" => "did a bad",
                 "roles" => ["artist"]
               })
    end

    test "only admins or mods can call this" do
      admin = user_fixture(%{roles: [:admin]})
      mod = user_fixture(%{roles: [:mod]})
      user = user_fixture()

      assert {:error, :unauthorized} =
               Accounts.update_admin_fields(user, user, %{
                 "roles" => ["mod"]
               })

      assert {:error, :unauthorized} =
               Accounts.update_admin_fields(user, user, %{
                 "roles" => ["admin"]
               })

      assert {:error, :unauthorized} =
               Accounts.update_admin_fields(user, user, %{
                 "roles" => ["artist"]
               })

      assert {:ok, _} =
               Accounts.update_admin_fields(mod, user, %{
                 "roles" => ["mod"]
               })

      assert {:ok, _} =
               Accounts.update_admin_fields(user, user, %{
                 "roles" => ["artist"]
               })

      assert {:ok, _} =
               Accounts.update_admin_fields(admin, user, %{
                 "roles" => ["admin"]
               })
    end

    test "validates field values" do
      admin = user_fixture(%{roles: [:admin]})
      user = user_fixture()

      assert {:error, changeset} =
               Accounts.update_admin_fields(admin, user, %{
                 "moderation_notes" =>
                   gen_random_string(500) <> "<script>alert('hello')</script>",
                 "roles" => ["cool"]
               })

      assert %{
               moderation_notes: [
                 "Disallowed HTML detected. Some tags, like <script>, are not allowed.",
                 "should be at most 500 character(s)"
               ],
               roles: ["is invalid"]
             } = errors_on(changeset)
    end

    test "validates role editing based on current user roles" do
      admin = user_fixture(%{roles: [:admin]})
      admin2 = user_fixture(%{roles: [:admin]})
      mod = user_fixture(%{roles: [:mod]})
      mod2 = user_fixture(%{roles: [:mod]})
      user = user_fixture()

      # Can't grant admin privs if you're a mod.
      assert {:error, changeset} =
               Accounts.update_admin_fields(mod, user, %{
                 "roles" => ["admin"]
               })

      assert %{
               roles: ["can't give user a role higher than your own"]
             } = errors_on(changeset)

      # Can't edit admin's roles if you're a mod.
      assert {:error, changeset} =
               Accounts.update_admin_fields(mod, admin, %{
                 "roles" => []
               })

      assert %{
               roles: ["can't edit roles for user with equal or higher privileges than you"]
             } = errors_on(changeset)

      # Mods can't edit other mods' roles.
      assert {:error, changeset} =
               Accounts.update_admin_fields(mod, mod2, %{
                 "roles" => []
               })

      assert %{
               roles: ["can't edit roles for user with equal or higher privileges than you"]
             } = errors_on(changeset)

      # Admins can't edit other admins' roles.
      assert {:error, changeset} =
               Accounts.update_admin_fields(mod, admin2, %{
                 "roles" => []
               })

      assert %{
               roles: ["can't edit roles for user with equal or higher privileges than you"]
             } = errors_on(changeset)

      # Mods and admins can edit themselves.
      assert {:ok, _} = Accounts.update_admin_fields(mod, mod, %{"roles" => []})
      assert {:ok, _} = Accounts.update_admin_fields(admin, admin, %{"roles" => []})
    end

    test "stale structs are refreshed when gating on permissions" do
      admin = user_fixture(%{roles: [:admin]})
      mod = user_fixture(%{roles: [:mod]})
      user = user_fixture()

      {:ok, _} = Accounts.update_admin_fields(admin, admin, %{roles: []})

      assert {:error, :unauthorized} =
               Accounts.update_admin_fields(admin, user, %{roles: [:admin]})

      {:ok, _} = Accounts.update_admin_fields(mod, mod, %{roles: []})
      assert {:error, :unauthorized} = Accounts.update_admin_fields(mod, user, %{roles: [:mod]})

      admin = user_fixture(%{roles: [:admin]})
      mod = user_fixture(%{roles: [:mod]})

      {:ok, _} = Accounts.update_admin_fields(admin, user, %{roles: [:admin]})
      assert {:ok, _} = Accounts.update_admin_fields(user, mod, %{roles: []})
      assert {:error, changeset} = Accounts.update_admin_fields(user, admin, %{roles: []})

      assert %{
               roles: ["can't edit roles for user with equal or higher privileges than you"]
             } = errors_on(changeset)
    end
  end

  describe "update_user_profile/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "validates profile", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_profile(
          user,
          user,
          %{
            name: String.duplicate("b", 40),
            bio: String.duplicate("a", 461),
            tags: ["foo", "bar"]
          }
        )

      assert %{
               bio: ["should be at most 160 character(s)"],
               name: ["should be at most 32 character(s)"]
             } = errors_on(changeset)
    end

    test "updates the user profile", %{user: user} do
      {:ok, %User{handle: handle} = user} =
        Accounts.update_user_profile(
          user,
          user,
          %{
            handle: "newhandle",
            name: "New Name",
            bio: "New Bio",
            tags: ["foo", "bar"]
          }
        )

      assert %User{
               name: "New Name",
               bio: "New Bio",
               tags: ["foo", "bar"],
               # handle doesn't get updated here!
               handle: ^handle
             } = Accounts.get_user_by_handle!(user.handle)
    end

    test "validates social media links", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_profile(
          user,
          user,
          %{
            twitter_handle: "@!123",
            instagram_handle: "@!123",
            facebook_url: "https://plus.google.com/hello",
            furaffinity_handle: "@!234",
            discord_handle: "@!234",
            artstation_handle: "@!234",
            deviantart_handle: "@!234",
            tumblr_handle: "@!234",
            mastodon_handle: "@!234",
            twitch_channel: "@!234",
            picarto_channel: "@!234",
            pixiv_url: "https://artstation.com/whatever",
            pixiv_handle: "@!234",
            tiktok_handle: "@!234",
            artfight_handle: "~!234"
          }
        )

      assert %{
               artfight_handle: [
                 "must be a valid Artfight handle, without the ~ sign."
               ],
               artstation_handle: [
                 "must be a valid Artstation handle."
               ],
               deviantart_handle: [
                 "must be a valid Deviantart handle."
               ],
               facebook_url: ["must be a valid Facebook URL."],
               furaffinity_handle: [
                 "must be a valid Furaffinity handle."
               ],
               instagram_handle: [
                 "must be a valid Instagram handle, without the @ sign."
               ],
               mastodon_handle: [
                 "must be a valid Mastodon handle, without the preceding @. For example: `foo@mastodon.social`."
               ],
               picarto_channel: [
                 "must be a valid Picarto channel name."
               ],
               pixiv_handle: ["must be a valid Pixiv handle."],
               pixiv_url: [
                 "must be a valid Pixiv URL, like `https://pixiv.net/en/users/12345`."
               ],
               tiktok_handle: [
                 "must be a valid TikTok handle, without the @ sign."
               ],
               tumblr_handle: ["must be a valid Tumblr handle."],
               twitch_channel: [
                 "must be a valid Twitch channel name."
               ],
               twitter_handle: [
                 "must be a valid Twitter handle, without the @ sign."
               ],
               discord_handle: [
                 "must be a valid Discord handle."
               ]
             } == errors_on(changeset)
    end

    test "updates social media links", %{user: user} do
      {:ok, %User{} = user} =
        Accounts.update_user_profile(
          user,
          user,
          %{
            twitter_handle: "foo1_",
            instagram_handle: "foo1_",
            facebook_url: "https://facebook.com/hello",
            furaffinity_handle: "foo1_-",
            discord_handle: "foo1_-#1234",
            artstation_handle: "foo1_",
            deviantart_handle: "foo1_",
            tumblr_handle: "foo1_",
            mastodon_handle: "foo1_@toot.cat",
            twitch_channel: "foo1_",
            picarto_channel: "foo1_",
            pixiv_url: "https://pixiv.net/en/users/12345",
            pixiv_handle: "bar",
            tiktok_handle: "foo1_",
            artfight_handle: "foo1_-"
          }
        )

      assert user.twitter_handle == "foo1_"
      assert user.instagram_handle == "foo1_"
      assert user.facebook_url == "https://facebook.com/hello"
      assert user.furaffinity_handle == "foo1_-"
      assert user.discord_handle == "foo1_-#1234"
      assert user.artstation_handle == "foo1_"
      assert user.deviantart_handle == "foo1_"
      assert user.tumblr_handle == "foo1_"
      assert user.mastodon_handle == "foo1_@toot.cat"
      assert user.twitch_channel == "foo1_"
      assert user.picarto_channel == "foo1_"
      assert user.pixiv_url == "https://pixiv.net/en/users/12345"
      assert user.pixiv_handle == "bar"
      assert user.tiktok_handle == "foo1_"
      assert user.artfight_handle == "foo1_-"
    end
  end

  @tag skip: "TODO"
  describe "make_pfp_images!/5" do
  end

  @tag skip: "TODO"
  describe "make_header_image!/5" do
  end

  describe "update_user_handle/3" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "validates handle", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_handle(user, valid_user_password(), %{
          handle: "b"
        })

      assert %{
               handle: ["should be at least 3 character(s)"]
             } = errors_on(changeset)

      {:error, changeset} =
        Accounts.update_user_handle(user, valid_user_password(), %{
          handle: "bad handle"
        })

      assert %{
               handle: ["only letters, numbers, and underscores are allowed"]
             } = errors_on(changeset)
    end

    test "updates handle with a valid password", %{user: user} do
      {:ok, %User{} = user} =
        Accounts.update_user_handle(
          user,
          valid_user_password(),
          %{
            handle: "newhandle"
          }
        )

      {:error, changeset} =
        Accounts.update_user_handle(user, "badpass", %{
          handle: "newhandle2"
        })

      assert %{
               current_password: ["is not valid"]
             } = errors_on(changeset)

      assert %User{
               handle: "newhandle"
             } = Accounts.get_user_by_handle!(user.handle)
    end

    test "does not require password to update if there's no user email", %{user: user} do
      Ecto.Query.from(u in User, where: u.id == ^user.id)
      |> Repo.update_all(set: [email: nil])

      user = Accounts.get_user(user.id)

      {:ok, %User{} = user} =
        Accounts.update_user_handle(
          user,
          valid_user_password(),
          %{
            handle: "newhandle"
          }
        )

      assert %User{
               handle: "newhandle"
             } = Accounts.get_user_by_handle!(user.handle)
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_handle(user, valid_user_password(), %{
          handle: "newhandle"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_new_user_email/3" do
    setup do
      user = unconfirmed_user_fixture()

      Ecto.Query.from(u in User, where: u.id == ^user.id)
      |> Repo.update_all(set: [email: nil])

      %{user: user}
    end

    test "validates email", %{user: user} do
      {:error, changeset} = Accounts.apply_new_user_email(user, %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} = Accounts.apply_new_user_email(user, %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = unconfirmed_user_fixture()

      {:error, changeset} = Accounts.apply_new_user_email(user, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "fails if user already has an email" do
      user = unconfirmed_user_fixture()

      assert {:error, :has_email} =
               Accounts.apply_new_user_email(user, %{email: unique_user_email()})
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_new_user_email(user, %{email: email})
      assert user.email == email
      assert Accounts.get_user(user.id).email != email
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{user: user} do
      %{email: email} = unconfirmed_user_fixture()

      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_user_email(user, valid_user_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user(user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      Accounts.deliver_update_email_instructions(
        user,
        "current@example.com",
        &extractable_user_token/1
      )

      email = user.email

      assert_delivered_email_matches(%_{
        to: [{_, ^email}],
        subject: "Update Your Banchan Art Email",
        text_body: text_body,
        html_body: html_body
      })

      token = extract_user_token(text_body)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"

      token = extract_user_token(html_body)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{password: too_long})

      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: valid_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_identifier_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_totp_secret/1" do
    test "adds a totp secret to the user" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      assert {:ok, %User{id: ^user_id} = user} = Accounts.generate_totp_secret(user)

      assert user.totp_secret
      assert Accounts.get_user(user.id).totp_secret
    end

    test "works fine if there's already a pending totp secret" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      {:ok, %User{totp_secret: secret1}} = Accounts.generate_totp_secret(user)

      assert {:ok, %User{id: ^user_id, totp_secret: secret2}} =
               Accounts.generate_totp_secret(user)

      refute secret1 == secret2
    end

    test "fails if user already has an activated totp secret" do
      user = unconfirmed_user_fixture()

      {:ok, %User{totp_secret: secret}} = Accounts.generate_totp_secret(user)
      {:ok, _user} = Accounts.activate_totp(user, NimbleTOTP.verification_code(secret))

      assert {:error, :totp_activated} = Accounts.generate_totp_secret(user)
    end
  end

  describe "deactivate_totp/1" do
    test "deactivates totp with a valid password" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      {:ok, %User{totp_secret: secret}} = Accounts.generate_totp_secret(user)

      {:ok, _user} = Accounts.activate_totp(user, NimbleTOTP.verification_code(secret))

      assert {:ok, %User{id: ^user_id} = user} =
               Accounts.deactivate_totp(user, valid_user_password())

      refute user.totp_secret
      refute user.totp_activated

      user = user |> Repo.reload()

      refute user.totp_secret
      refute user.totp_activated
    end

    test "fails with an invalid password" do
      user = unconfirmed_user_fixture()

      {:ok, %User{totp_secret: secret}} = Accounts.generate_totp_secret(user)

      {:ok, _user} = Accounts.activate_totp(user, NimbleTOTP.verification_code(secret))

      assert {:error, :invalid_password} = Accounts.deactivate_totp(user, "badpass")
    end
  end

  describe "activate_totp/2" do
    test "activates totp with an existing secret" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      {:ok, %User{totp_secret: secret}} = Accounts.generate_totp_secret(user)

      assert {:ok, %User{id: ^user_id} = user} =
               Accounts.activate_totp(user, NimbleTOTP.verification_code(secret))

      assert user.totp_secret
      assert user.totp_activated

      user = user |> Repo.reload()

      assert user.totp_secret
      assert user.totp_activated
    end

    test "fails with an invalid token" do
      user = unconfirmed_user_fixture()

      {:ok, _user} = Accounts.generate_totp_secret(user)

      assert {:error, :invalid_token} = Accounts.activate_totp(user, "1234567")
    end
  end

  describe "update_maturity/2" do
    test "updates maturity setting" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      refute user.mature_ok
      refute user.uncensored_mature

      assert {:ok, %User{id: ^user_id} = user} =
               Accounts.update_maturity(user, %{
                 mature_ok: true,
                 uncensored_mature: true
               })

      assert user.mature_ok
      assert user.uncensored_mature
    end
  end

  describe "update_muted/2" do
    test "updates muted words list" do
      %User{id: user_id} = user = unconfirmed_user_fixture()

      refute user.muted

      assert {:ok, %User{id: ^user_id} = user} =
               Accounts.update_muted(user, %{
                 muted: "foo bar"
               })

      assert user.muted == "foo bar"
    end

    test "validates muted words" do
      user = unconfirmed_user_fixture()

      assert {:ok, _} =
               Accounts.update_muted(user, %{
                 muted: gen_random_string(1000)
               })

      assert {:error, changeset} =
               Accounts.update_muted(user, %{
                 muted: gen_random_string(1001)
               })

      assert %{
               muted: ["should be at most 1000 character(s)"]
             } = errors_on(changeset)
    end
  end
end
