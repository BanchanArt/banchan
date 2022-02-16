defmodule Banchan.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Commissions` context.
  """
  @dialyzer [:no_return]

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
      Banchan.Offerings.new_offering(studio, %{
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
      |> then(&Banchan.Commissions.create_event(:comment, user, commission, [], &1))

    event
  end
end
