defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  alias Banchan.Offerings.Offering
  alias Banchan.Repo

  def new_offering(_, false, _) do
    {:error, :unauthorized}
  end

  def new_offering(studio, _current_user_member?, attrs) do
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

  def update_offering(_, false, _) do
    {:error, :unauthorized}
  end

  def update_offering(%Offering{} = offering, _current_user_member?, attrs) do
    change_offering(offering, attrs) |> Repo.update(returning: true)
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

  def offering_available_slots(%Offering{} = offering) do
    Repo.one(
      from(c in Banchan.Commissions.Commission,
        join: o in assoc(c, :offering),
        where: o.id == ^offering.id,
        where: c.status != :withdrawn and c.status != :approved and c.status != :submitted,
        group_by: [c.offering_id, o.slots],
        select:
          fragment(
            "CASE WHEN o1.slots IS NULL THEN NULL WHEN COUNT(c0) > o1.slots THEN 0 ELSE o1.slots - count(c0) END"
          )
      )
    )
  end

  def offering_available_proposals(%Offering{} = offering) do
    Repo.one(
      from(c in Banchan.Commissions.Commission,
        join: o in assoc(c, :offering),
        where: o.id == ^offering.id,
        where: c.status == :submitted,
        group_by: [c.offering_id, o.max_proposals],
        select:
          fragment(
            "CASE WHEN o1.max_proposals IS NULL THEN NULL WHEN COUNT(c0) > o1.max_proposals THEN 0 ELSE o1.max_proposals - count(c0) END"
          )
      )
    )
  end
end
