defmodule Banchan.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Commissions` context.
  """
  @dialyzer [:no_return]

  import Banchan.AccountsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Commissions

  def commission_fixture(attrs \\ %{}) do
    user = user_fixture()
    studio = studio_fixture([user])
    offering = offering_fixture(studio)

    {:ok, commission} =
      Commissions.create_commission(
        user,
        studio,
        offering,
        [],
        [],
        attrs
        |> Enum.into(%{
          title: "some title",
          description: "Some Description",
          tos_ok: true
        })
      )

    commission
  end
end
