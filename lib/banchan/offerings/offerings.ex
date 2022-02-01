defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  alias Banchan.Offerings.Offering
  alias Banchan.Repo

  def new_offering(studio, attrs) do
    %Offering{studio_id: studio.id}
    |> Offering.changeset(attrs)
    |> Repo.insert()
  end

  def get_offering_by_type!(type, current_user_member?) do
    Repo.one!(
      from o in Offering,
        where: o.type == ^type and (^current_user_member? or not o.hidden)
    )
    |> Repo.preload(:options)
  end

  def change_offering(%Offering{} = offering, attrs \\ %{}) do
    Offering.changeset(offering, attrs)
  end

  def update_offering(%Offering{} = offering, attrs) do
    change_offering(offering, attrs) |> Repo.update()
  end

  def offering_base_price(%Offering{} = offering) do
    if Enum.empty?(offering.options) do
      nil
    else
      offering.options
      |> Enum.filter(& &1.default)
      |> Enum.map(&(&1.price || Money.new(0, :USD)))
      |> Enum.reduce(Money.new(0, :USD), &Money.add(&1, &2))
    end
  end

  def offering_available_slots(%Offering{slots: nil}) do
    nil
  end

  def offering_available_slots(%Offering{} = offering) do
    used_slots =
      Repo.one(
        from c in Banchan.Commissions.Commission,
          where: c.offering_id == ^offering.id,
          where: c.status != :closed and c.status != :pending,
          select: count(c)
      )

    if used_slots > offering.slots do
      0
    else
      offering.slots - used_slots
    end
  end

  def offering_available_proposals(%Offering{max_proposals: nil}) do
    nil
  end

  def offering_available_proposals(%Offering{} = offering) do
    used_proposals =
      Repo.one(
        from c in Banchan.Commissions.Commission,
          where: c.offering_id == ^offering.id,
          where: c.status == :pending,
          select: count(c)
      )

    if used_proposals > offering.max_proposals do
      0
    else
      offering.max_proposals - used_proposals
    end
  end
end
