defmodule Banchan.StudiosTest do
  @moduledoc """
  Tests for Studios-related functionality.
  """
  use Banchan.DataCase

  import Mox

  import Banchan.AccountsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias Banchan.Notifications
  alias Banchan.Repo

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
      studio_url = "http://localhost:4000/studios/#{studio_handle}"

      Banchan.StripeAPI.Mock
      |> expect(:create_account, fn attrs ->
        assert "express" == attrs.type
        assert %{payouts: %{schedule: %{interval: "manual"}}} == attrs.settings
        assert studio_url == attrs.business_profile.url
        {:ok, %Stripe.Account{id: stripe_id}}
      end)

      {:ok, studio} =
        Banchan.Studios.new_studio(
          %Studio{artists: [user]},
          studio_url,
          %{
            name: studio_name,
            handle: studio_handle
          }
        )

      assert studio.stripe_id == stripe_id
      assert studio.handle == studio_handle
      assert studio.name == studio_name

      Repo.transaction(fn ->
        subscribers =
          studio
          |> Notifications.studio_subscribers()
          |> Enum.map(& &1.id)

        assert subscribers == [user.id]
      end)
    end
  end

  describe "listing" do
    test "list all studios" do
      studio = studio_fixture(%Studio{})

      assert studio.id in Enum.map(Studios.list_studios(), & &1.id)
    end

    test "list user studios and studio members" do
      user = user_fixture()
      studio_handle = unique_studio_handle()
      studio_name = unique_studio_name()
      studio_url = "http://localhost:4000/studios/#{studio_handle}"

      Banchan.StripeAPI.Mock
      |> expect(:create_account, fn _ ->
        {:ok, %Stripe.Account{id: unique_stripe_id()}}
      end)

      {:ok, studio} =
        Banchan.Studios.new_studio(
          %Studio{artists: [user]},
          studio_url,
          valid_studio_attributes(%{
            name: studio_name,
            handle: studio_handle
          })
        )

      assert Enum.map(Studios.list_studios_for_user(user), & &1.id) == [studio.id]
      assert Enum.map(Studios.list_studio_members(studio), & &1.id) == [user.id]
      assert Studios.is_user_in_studio?(user, studio)
    end
  end

  describe "onboarding" do
    test "create onboarding link" do
      studio = studio_fixture(%Studio{})
      link_url = "http://link_url"

      Banchan.StripeAPI.Mock
      |> expect(:create_account_link, fn params ->
        assert %{
                 account: studio.stripe_id,
                 type: "account_onboarding",
                 return_url: "http://url1",
                 refresh_url: "http://url2"
               } == params

        {:ok, %Stripe.AccountLink{url: link_url}}
      end)

      assert Studios.get_onboarding_link!(studio, "http://url1", "http://url2") == link_url
    end
  end

  describe "payouts and such" do
  end
end
