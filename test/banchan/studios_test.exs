defmodule Banchan.StudiosTest do
  @moduledoc """
  Tests for Studios-related functionality.
  """
  use Banchan.DataCase

  import Mox

  import Banchan.AccountsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Studios.Studio

  setup :verify_on_exit!

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

  describe "creation" do
    test "create and enable a studio" do
      user = user_fixture()
      stripe_id = unique_stripe_id()
      studio_handle = unique_studio_handle()
      studio_name = unique_studio_name()

      Banchan.StripeAPI.Mock
      |> expect(:create_account, fn attrs ->
        assert %{payouts: %{schedule: %{interval: "manual"}}} == attrs.settings
        {:ok, %Stripe.Account{id: stripe_id}}
      end)

      {:ok, studio} =
        Banchan.Studios.new_studio(
          %Studio{artists: [user]},
          "http://localhost:4000/studios/#{studio_handle}",
          %{
            name: studio_name,
            handle: studio_handle
          }
        )

      assert studio.stripe_id == stripe_id
      assert studio.handle == studio_handle
      assert studio.name == studio_name
    end
  end
end
