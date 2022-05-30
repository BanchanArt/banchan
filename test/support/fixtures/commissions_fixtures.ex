defmodule Banchan.CommissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Banchan.Commissions` context.
  """
  @dialyzer [:no_return]

  import Banchan.AccountsFixtures
  import Banchan.OfferingsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Accounts.User
  alias Banchan.Commissions
  alias Banchan.Commissions.Commission

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

  def invoice_fixture(%User{} = actor, %Commission{} = commission, data) do
    {:ok, invoice} = Commissions.invoice(actor, commission, true, [], data)
    invoice
  end
end
