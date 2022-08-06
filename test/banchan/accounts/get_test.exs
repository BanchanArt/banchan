defmodule Banchan.AccountsTest.Get do
  @moduledoc """
  Tests for functionality related to reading/fetching account information/
  """
  use Banchan.DataCase, async: true

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.{User, UserFilter}

  describe "list_users/3" do
    test "lists existing users, in insertion order" do
      %User{id: admin_id} = admin = user_fixture(%{roles: [:admin]})
      %User{id: user1_id} = user_fixture()
      %User{id: user2_id} = unconfirmed_user_fixture()

      assert %_{
               page_number: 1,
               page_size: 24,
               entries: [%User{id: ^admin_id}, %User{id: ^user1_id}, %User{id: ^user2_id}],
               total_entries: 3,
               total_pages: 1
             } = Accounts.list_users(admin, %UserFilter{})
    end

    test "does not list deactivated users" do
      user = unconfirmed_user_fixture()

      {:ok, _} = Accounts.deactivate_user(user, user, valid_user_password())

      assert %_{
               page_number: 1,
               page_size: 24,
               entries: [],
               total_entries: 0,
               total_pages: 1
             } = Accounts.list_users(user, %UserFilter{})
    end
  end

  describe "get_user/1" do
    test "does not return the user if the id does not exist" do
      refute Accounts.get_user(1_234_567)
    end

    test "does not return the user if the user exists but is deactivated" do
      %{id: id} = user = unconfirmed_user_fixture()
      assert %User{id: ^id} = Accounts.get_user(id)
      {:ok, _user} = Accounts.deactivate_user(user, user, valid_user_password())
      refute Accounts.get_user(id)
    end

    test "returns the user if the user id exists" do
      %{id: id} = unconfirmed_user_fixture()
      assert %User{id: ^id} = Accounts.get_user(id)
    end
  end

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = unconfirmed_user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end

    test "does not return the user if the user is deactivated" do
      %{id: id} = user = unconfirmed_user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
      {:ok, user} = Accounts.deactivate_user(user, user, valid_user_password())
      refute Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_handle!/1" do
    test "does not return the user if the handle does not exist" do
      catch_error(Accounts.get_user_by_handle!("unknown"))
    end

    test "does not return the user if the user exists but is deactivated" do
      %{id: id} = user = unconfirmed_user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_handle!(user.handle)
      {:ok, user} = Accounts.deactivate_user(user, user, valid_user_password())
      catch_error(Accounts.get_user_by_handle!(user.handle))
    end

    test "returns the user if the email exists" do
      %{id: id} = user = unconfirmed_user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_handle!(user.handle)
    end
  end

  describe "get_user_by_identifier_and_password/3" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_identifier_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = unconfirmed_user_fixture()
      refute Accounts.get_user_by_identifier_and_password(user.email, "invalid")
    end

    test "does not return the user if the user is deactivated, by default" do
      %{id: id} = user = unconfirmed_user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_identifier_and_password(user.email, valid_user_password())

      {:ok, user} = Accounts.deactivate_user(user, user, valid_user_password())
      refute Accounts.get_user_by_identifier_and_password(user.email, valid_user_password())
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = unconfirmed_user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_identifier_and_password(user.email, valid_user_password())
    end

    test "returns the user if the user is deactivated and the `:include_deactivated?` option is passed in." do
      %{id: id} = user = unconfirmed_user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_identifier_and_password(user.email, valid_user_password())

      {:ok, user} = Accounts.deactivate_user(user, user, valid_user_password())

      assert Accounts.get_user_by_identifier_and_password(user.email, valid_user_password(),
               include_deactivated?: true
             )
    end
  end

  describe "can_modify_user?/2" do
    test "true if the target is the same user as the actor" do
      user = user_fixture()
      assert Accounts.can_modify_user?(user, user)
    end

    test "true if the target is not the same user as the actor, but the actor is a mod" do
      actor = user_fixture(%{roles: [:mod]})
      target = user_fixture()
      assert Accounts.can_modify_user?(actor, target)
    end

    test "true if the target is not the same user as the actor, but the actor is an admin" do
      actor = user_fixture(%{roles: [:admin]})
      target = user_fixture()
      assert Accounts.can_modify_user?(actor, target)
    end

    test "false if the target is not the same user as the actor, and the actor does not have admin/mod privileges" do
      actor = user_fixture()
      artist = user_fixture(%{roles: [:artist]})
      target = user_fixture()
      refute Accounts.can_modify_user?(actor, target)
      refute Accounts.can_modify_user?(artist, target)
    end
  end

  describe "days_until_deletion/1" do
    test "returns the number of days until a deactivated user is deleted from the system" do
      user = user_fixture()
      {:ok, user} = Accounts.deactivate_user(user, user, valid_user_password())
      # NB(@zkat): This is every so slightly racy, but it's probably ok
      # 99.999% of the time. Come up with something better if this ends up
      # causing headaches.
      assert 30 == Accounts.days_until_deletion(user)
    end

    test "errors if the user is not deactivated" do
      user = user_fixture()
      catch_error(Accounts.days_until_deletion(user))
    end
  end

  describe "active_user?/1" do
    test "returns true if the user is active" do
      user = user_fixture()
      assert Accounts.active_user?(user)
    end

    test "returns false if the user is deactivated" do
      user = user_fixture()
      {:ok, user} = Accounts.deactivate_user(user, user, valid_user_password())
      refute Accounts.active_user?(user)
    end
  end

  @tag skip: "TODO"
  describe "user_pfp_img!/1" do
  end

  @tag skip: "TODO"
  describe "user_pfp_thumb!/1" do
  end

  @tag skip: "TODO"
  describe "user_header_img!/1" do
  end
end
