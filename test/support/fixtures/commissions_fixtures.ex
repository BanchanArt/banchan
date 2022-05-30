defmodule Banchan.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Commissions` context.
  """
  @dialyzer [:no_return]

  import Mox

  alias Banchan.Accounts
  alias Banchan.Commissions
  alias Banchan.Offerings
  alias Banchan.Studios
  alias Banchan.Studios.Studio

  def unique_studio_name, do: "studio#{System.unique_integer()}"
  def unique_studio_handle, do: "studio#{System.unique_integer()}"
  def unique_stripe_id, do: "mock_stripe_id#{System.unique_integer()}"

  def stripe_account_mock() do
    Banchan.StripeAPI.Mock
    |> expect(:create_account, fn _ ->
      {:ok, %Stripe.Account{id: "mock_stripe_id#{System.unique_integer()}"}}
    end)
  end

  def commission_fixture(attrs \\ %{}) do
    {:ok, user} =
      Accounts.register_admin(%{
        handle: "test-admin",
        email: "test@example.com",
        password: "foobarbazquux",
        password_confirmation: "foobarbazquux"
      })

    stripe_account_mock()

    {:ok, studio} =
      Studios.new_studio(
        %Studio{artists: [user]},
        "http://localhost:4000/studios/test-studio",
        %{
          handle: "test-studio",
          name: "Test Studio",
          description: "stuff for testing"
        }
      )

    {:ok, offering} =
      Offerings.new_offering(studio, true, %{
        type: "illustration",
        index: 0,
        name: "Illustration",
        description: "A detailed illustration with full rendering and background.",
        open: true
      })

    {:ok, commission} =
      Commissions.create_commission(
        user,
        studio,
        offering,
        [],
        [],
        attrs |> Enum.into(%{
          title: "some title",
          description: "Some Description",
          tos_ok: true
        })
      )

    commission
  end

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, user} =
      Banchan.Accounts.register_admin(%{
        handle: "test-admin",
        email: "test@example.com",
        password: "foobarbazquux",
        password_confirmation: "foobarbazquux"
      })

    {:ok, studio} =
      Banchan.Studios.new_studio(
        %Banchan.Studios.Studio{artists: [user]},
        "http://localhost:4000/studios/test-studio",
        %{
          handle: "test-studio",
          name: "Test Studio",
          description: "stuff for testing"
        }
      )

    {:ok, offering} =
      Banchan.Offerings.new_offering(studio, true, %{
        type: "illustration",
        index: 0,
        name: "Illustration",
        description: "A detailed illustration with full rendering and background.",
        open: true
      })

    {:ok, commission} =
      Banchan.Commissions.create_commission(user, studio, offering, [], %{
        title: "Please do this thing",
        description: "the thing to do is like so",
        tos_ok: true
      })

    {:ok, event} =
      attrs
      |> Enum.into(%{})
      |> then(&Banchan.Commissions.create_event(:comment, user, commission, true, [], &1))

    event
  end
end
