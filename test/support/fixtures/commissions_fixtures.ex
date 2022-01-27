defmodule Banchan.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Commissions` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        data: %{},
        type: "some type"
      })
      |> Banchan.Commissions.create_event()

    event
  end
end
