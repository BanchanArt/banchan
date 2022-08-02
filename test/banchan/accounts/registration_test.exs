defmodule Banchan.AccountsTest.Registration do
  @moduledoc """
  Tests for functionality related to user registration.
  """
  use Banchan.DataCase, async: true

  alias Ueberauth.Auth

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.{User, UserFilter}

  describe "register_user/1" do
    test "requires handle, email, and password to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{
               handle: ["can't be blank"],
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates handle, email, and password when given" do
      {:error, changeset} =
        Accounts.register_user(%{handle: "x!", email: "not valid", password: "not valid"})

      assert %{
               handle: [
                 "should be at least 3 character(s)",
                 "only letters, numbers, and underscores are allowed"
               ],
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates handle uniqueness" do
      %{handle: handle} = unconfirmed_user_fixture()
      {:error, changeset} = Accounts.register_user(%{handle: handle})
      assert "already exists" in errors_on(changeset).handle

      # Now try with the upper cased handle too, to check that handle case is ignored.
      {:error, changeset} = Accounts.register_user(%{handle: String.upcase(handle)})
      assert "already exists" in errors_on(changeset).handle
    end

    test "validates email uniqueness" do
      %{email: email} = unconfirmed_user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "register_admin/1" do
    test "registers users with a hashed password and adds :admin role" do
      email = unique_user_email()
      handle = unique_user_handle()

      {:ok, user} =
        Accounts.register_admin(%{handle: handle, email: email, password: valid_user_password()})

      assert user.handle == handle
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
      assert user.roles == [:admin]
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :handle, :email]
    end

    test "allows fields to be set" do
      handle = unique_user_handle()
      email = unique_user_email()
      password = valid_user_password()

      changeset =
        Accounts.change_user_registration(
          %User{},
          valid_user_attributes(handle: handle, email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :handle) == handle
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "handle_oauth/1" do
    test "Twitter: registers a new user when logging in" do
      auth = %Auth{
        provider: :twitter,
        uid: gen_random_string(),
        info: %{
          email: unique_user_email(),
          nickname: unique_user_handle(),
          name: gen_random_string(),
          description: gen_random_string()
        }
      }

      assert {:ok, %User{id: user_id} = user} = Accounts.handle_oauth(auth)

      assert user.handle == auth.info.nickname
      assert user.twitter_uid == auth.uid
      assert user.twitter_handle == auth.info.nickname
      assert user.email == auth.info.email
      assert user.name == auth.info.name
      assert user.bio == auth.info.description

      admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id} | _] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    test "Twitter: massages incoming fields that don't pass our own validations" do
      auth = %Auth{
        provider: :twitter,
        uid: gen_random_string(),
        info: %{
          email: "not an email",
          nickname: "1" <> unique_user_handle() <> "!",
          name: gen_random_string(33),
          description: gen_random_string(161)
        }
      }

      assert {:ok, %User{id: user_id} = user} = Accounts.handle_oauth(auth)

      assert user.handle =~ ~r/^user\d+$/
      assert user.email == nil
      assert user.name == binary_part(auth.info.name, 0, 32)
      assert user.bio == binary_part(auth.info.description, 0, 160)

      admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id} | _] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    test "Twitter: returns an existing user." do
      auth = %Auth{
        provider: :twitter,
        uid: gen_random_string(),
        info: %{
          email: unique_user_email(),
          nickname: unique_user_handle(),
          name: gen_random_string(),
          description: gen_random_string()
        }
      }

      assert {:ok, %User{id: user_id}} = Accounts.handle_oauth(auth)
      assert {:ok, %User{id: ^user_id}} = Accounts.handle_oauth(auth)

      %User{id: admin_id} = admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id}, %User{id: ^admin_id}] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    @tag skip: "TODO"
    test "Twitter: set Twitter pfp as Banchan pfp" do
    end

    test "Discord: registers a new user when logging in" do
      auth = %Auth{
        provider: :discord,
        uid: gen_random_string(),
        info: %{
          email: unique_user_email()
        },
        extra: %{
          raw_info: %{
            user: %{
              "username" => unique_user_handle(),
              "discriminator" => gen_random_string()
            }
          }
        }
      }

      assert {:ok, %User{id: user_id} = user} = Accounts.handle_oauth(auth)

      assert user.handle ==
               auth.extra.raw_info.user["username"] <>
                 "_" <> auth.extra.raw_info.user["discriminator"]

      assert user.discord_uid == auth.uid

      assert user.discord_handle ==
               auth.extra.raw_info.user["username"] <>
                 "#" <> auth.extra.raw_info.user["discriminator"]

      assert user.email == auth.info.email

      assert user.name ==
               auth.extra.raw_info.user["username"] <>
                 "#" <> auth.extra.raw_info.user["discriminator"]

      assert user.bio == nil

      admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id} | _] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    test "Discord: massages incoming fields that don't pass our own validations" do
      auth = %Auth{
        provider: :discord,
        uid: gen_random_string(),
        info: %{
          email: "not an email"
        },
        extra: %{
          raw_info: %{
            user: %{
              "username" => "1" <> unique_user_handle() <> "!",
              "discriminator" => gen_random_string(34)
            }
          }
        }
      }

      assert {:ok, %User{id: user_id} = user} = Accounts.handle_oauth(auth)

      assert user.email == nil

      assert user.name ==
               (auth.extra.raw_info.user["username"] <>
                  "#" <> auth.extra.raw_info.user["discriminator"])
               |> binary_part(0, 32)

      assert user.handle =~ ~r/^user\d+$/

      admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id} | _] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    test "Discord: returns an existing user." do
      auth = %Auth{
        provider: :discord,
        uid: gen_random_string(),
        info: %{
          email: unique_user_email()
        },
        extra: %{
          raw_info: %{
            user: %{
              "username" => unique_user_handle(),
              "discriminator" => gen_random_string()
            }
          }
        }
      }

      assert {:ok, %User{id: user_id}} = Accounts.handle_oauth(auth)
      assert {:ok, %User{id: ^user_id}} = Accounts.handle_oauth(auth)

      %User{id: admin_id} = admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id}, %User{id: ^admin_id}] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    @tag skip: "TODO"
    test "Discord: set Discord pfp as Banchan pfp" do
    end

    test "Google: registers a new user when logging in" do
      auth = %Auth{
        provider: :google,
        uid: gen_random_string(),
        info: %{
          email: unique_user_email()
        }
      }

      assert {:ok, %User{id: user_id} = user} = Accounts.handle_oauth(auth)

      assert user.handle =~ ~r/^user\d+$/
      assert user.google_uid == auth.uid
      assert user.email == auth.info.email
      assert user.name == nil
      assert user.bio == nil

      admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id} | _] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    test "Google: massages incoming fields that don't pass our own validations" do
      auth = %Auth{
        provider: :google,
        uid: gen_random_string(),
        info: %{
          email: "not an email"
        }
      }

      assert {:ok, %User{id: user_id} = user} = Accounts.handle_oauth(auth)

      assert user.handle =~ ~r/^user\d+$/
      assert user.email == nil

      admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id} | _] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    test "Google: returns an existing user." do
      auth = %Auth{
        provider: :google,
        uid: gen_random_string(),
        info: %{
          email: unique_user_email()
        }
      }

      assert {:ok, %User{id: user_id}} = Accounts.handle_oauth(auth)
      assert {:ok, %User{id: ^user_id}} = Accounts.handle_oauth(auth)

      %User{id: admin_id} = admin = user_fixture(%{roles: [:admin]})

      assert [%User{id: ^user_id}, %User{id: ^admin_id}] =
               Accounts.list_users(admin, %UserFilter{}).entries |> Enum.sort_by(& &1.id)
    end

    @tag skip: "TODO"
    test "Google: set Google pfp as Banchan pfp" do
    end
  end
end
