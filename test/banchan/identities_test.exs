defmodule Banchan.IdentitiesTest do
  @moduledoc """
  Tests for Accounts/User-related functionality.
  """
  use Banchan.DataCase, async: true

  import Banchan.AccountsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Identities

  describe "get_user_or_studio_by_handle/1" do
    test "returns an error tuple when neither user or studio exists" do
      assert {:error, _} = Identities.get_user_or_studio_by_handle("xyzzy")
    end

    test "returns the user if the handle exists" do
      user = user_fixture()
      {:ok, found} = Identities.get_user_or_studio_by_handle(user.handle)
      assert found.id == user.id
    end

    test "returns the studio if the handle exists" do
      user = user_fixture()
      studio = studio_fixture([user])
      {:ok, found} = Identities.get_user_or_studio_by_handle(studio.handle)
      assert found.id == studio.id
    end
  end

  describe "validate_uniqueness_of_handle" do
    test "returns false if there is a user with the same handle" do
      user = user_fixture(handle: "xyzzy")
      refute Identities.validate_uniqueness_of_handle(user.handle)
    end

    test "returns false if there is a studio with the same handle" do
      user = user_fixture()
      studio = studio_fixture([user], %{handle: "plugh"})
      assert "plugh" == studio.handle
      refute Identities.validate_uniqueness_of_handle(studio.handle)
    end

    test "returns true if there is no studio or user with the same handle/handle" do
      assert(Identities.validate_uniqueness_of_handle("foobar"))
    end
  end
end
