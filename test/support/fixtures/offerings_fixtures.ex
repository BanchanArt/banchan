defmodule Banchan.OfferingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Offerings` context.
  """

  alias Banchan.Accounts
  alias Banchan.Offerings
  alias Banchan.Payments

  def offering_fixture(studio, attrs \\ %{}) do
    type = "offering-type#{System.unique_integer()}"
    name = "offering-name#{System.unique_integer()}"
    description = "offering-description#{System.unique_integer()}"

    {:ok, offering} =
      Offerings.new_offering(
        Accounts.system_user(),
        studio,
        Enum.into(
          %{
            type: type,
            index: 0,
            name: name,
            description: description,
            currency: Payments.platform_currency(),
            open: true
          },
          attrs
        )
      )

    offering
  end
end
