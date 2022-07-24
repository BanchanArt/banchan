defmodule Banchan.OfferingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Offerings` context.
  """
  alias Banchan.Offerings

  def offering_fixture(studio, attrs \\ %{}) do
    type = "offering-type#{System.unique_integer()}"
    name = "offering-name#{System.unique_integer()}"
    description = "offering-description#{System.unique_integer()}"

    {:ok, offering} =
      Offerings.new_offering(
        nil,
        studio,
        true,
        Enum.into(
          %{
            type: type,
            index: 0,
            name: name,
            description: description,
            open: true
          },
          attrs
        ),
        nil
      )

    offering
  end
end
