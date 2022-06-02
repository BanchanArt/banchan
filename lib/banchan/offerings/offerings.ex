defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  alias Banchan.Commissions.Commission
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
    {slots, count} =
      Repo.one(
        from(o in Offering,
          left_join:
            comms in subquery(
              from(c in Commission,
                where:
                  c.offering_id == ^offering.id and
                    (c.status != :withdrawn and c.status != :approved and c.status != :submitted)
              )
            ),
          where: o.id == ^offering.id,
          group_by: [o.id, o.slots],
          select: {o.slots, count(comms)}
        )
      )

    cond do
      is_nil(slots) ->
        nil

      count > slots ->
        0

      true ->
        slots - count
    end
  end

  def offering_available_proposals(%Offering{} = offering) do
    {max, count} =
      Repo.one(
        from(o in Offering,
          left_join:
            comms in subquery(
              from(c in Commission,
                where: c.offering_id == ^offering.id and c.status == :submitted
              )
            ),
          where: o.id == ^offering.id,
          group_by: [o.id, o.max_proposals],
          select: {o.max_proposals, count(comms)}
        )
      )

    cond do
      is_nil(max) ->
        nil

      count > max ->
        0

      true ->
        max - count
    end
  end
end
