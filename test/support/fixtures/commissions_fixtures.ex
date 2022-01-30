defmodule Banchan.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Commissions` context.
  """

  @doc """
  Generate a event.
  """
  def event_fixture(actor, commission, attrs \\ %{}) do
    {:ok, event} =
      attrs
      |> Enum.into(%{
        data: %{},
        type: "some type"
      })
      |> then(&Banchan.Commissions.create_event(actor, commission, &1))

    event
  end
end
