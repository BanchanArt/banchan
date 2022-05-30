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
      user = user_fixture()
      existing_studio = studio_fixture([user])

      changeset =
        Studio.profile_changeset(
          %Studio{},
          %{name: "valid name", handle: existing_studio.handle}
        )

      refute changeset.valid?
    end

    test "cannot use an existing user handle" do
      user = user_fixture()

      changeset =
        Studio.profile_changeset(
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

  describe "updating" do
    test "update studio profile" do
      user = user_fixture()
      studio = studio_fixture([user])

      attrs = %{
        name: "new name",
        handle: "new-handle",
        description: "new description",
        summary: "new summary",
        default_terms: "new terms",
        default_template: "new template"
      }

      {:error, :unauthorized} =
        Studios.update_studio_profile(
          studio,
          false,
          attrs
        )

      from_db = Repo.get!(Studio, studio.id) |> Repo.preload(:artists)
      assert from_db.name != attrs.name

      {:ok, studio} =
        Studios.update_studio_profile(
          studio,
          true,
          attrs
        )

      assert studio.name == "new name"
      assert studio.handle == "new-handle"
      assert studio.description == "new description"
      assert studio.summary == "new summary"
      assert studio.default_terms == "new terms"
      assert studio.default_template == "new template"

      from_db = Repo.get!(Studio, studio.id) |> Repo.preload(:artists)
      assert studio.name == from_db.name
      assert studio.handle == from_db.handle
      assert studio.description == from_db.description
      assert studio.summary == from_db.summary
      assert studio.default_terms == from_db.default_terms
      assert studio.default_template == from_db.default_template
    end

    test "update_stripe_state" do
      user = user_fixture()
      studio = studio_fixture([user])
      Studios.subscribe_to_stripe_state(studio)

      Studios.update_stripe_state(studio.stripe_id, %Stripe.Account{
        charges_enabled: true,
        details_submitted: true
      })

      from_db = Repo.get!(Studio, studio.id)
      assert from_db.stripe_charges_enabled == true
      assert from_db.stripe_details_submitted == true

      topic = "studio_stripe_state:#{studio.stripe_id}"

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "charges_state_changed",
        payload: true
      }

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "details_submitted_changed",
        payload: true
      }

      Studios.unsubscribe_from_stripe_state(studio)
    end
  end

  describe "listing" do
    test "list all studios" do
      user = user_fixture()
      studio = studio_fixture([user])

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
      user = user_fixture()
      studio = studio_fixture([user])
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

  describe "charges and payouts" do
    test "charges_enabled?" do
      user = user_fixture()
      studio = studio_fixture([user])

      Studios.update_stripe_state(studio.stripe_id, %Stripe.Account{
        charges_enabled: true
      })

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_account, fn _ ->
        {:ok, %Stripe.Account{charges_enabled: true}}
      end)

      assert !Studios.charges_enabled?(studio)
      assert Studios.charges_enabled?(studio, true)
    end
  end
end
