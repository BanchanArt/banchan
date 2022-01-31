defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  alias Banchan.Repo
  alias Banchan.Offerings.Offering

  def new_offering(studio, attrs) do
    %Offering{studio_id: studio.id}
    |> Offering.changeset(attrs)
    |> Repo.insert()
  end

  def get_offering_by_type!(type) do
    Repo.one!(from o in Offering, where: o.type == ^type) |> Repo.preload(:options)
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
end
