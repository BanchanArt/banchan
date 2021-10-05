defmodule Banchan.StudiosTest do
  @moduledoc """
  Tests for Studios-related functionality.
  """
  use Banchan.DataCase

  import Banchan.AccountsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Studios.Studio

  describe "validation" do
    test "cannot use an existing handle" do
      existing_studio = studio_fixture(%Studio{})

      changeset =
        Studio.changeset(
          %Studio{},
          %{name: "valid name", handle: existing_studio.handle}
        )

      refute changeset.valid?
    end

    test "cannot use an existing user handle" do
      user = user_fixture()

      changeset =
        Studio.changeset(
          %Studio{},
          %{name: "valid name", handle: user.handle}
        )

      refute changeset.valid?
    end
  end
end
