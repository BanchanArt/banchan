defmodule Banchan.Offerings do
  @moduledoc """
  Main context module for Offerings.
  """
  import Ecto.Query, warn: false

  alias Banchan.Repo
  alias Banchan.Offerings.{Offering, OfferingOption}

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

  @doc """
  Returns the list of OfferingOptions for a Offering.

  ## Examples

      iex> list_offering_options(offering)
      [%OfferingOption{}, ...]

  """
  def list_offering_options(offering) do
    Repo.all(OfferingOption, where: [offering_id: offering.id])
  end

  @doc """
  Gets a single offering_option.

  Raises `Ecto.NoResultsError` if the Offering option does not exist.

  ## Examples

      iex> get_offering_option!(123)
      %OfferingOption{}

      iex> get_offering_option!(456)
      ** (Ecto.NoResultsError)

  """
  def get_offering_option!(id), do: Repo.get!(OfferingOption, id)

  @doc """
  Adds a offering option to a offering.

  ## Examples

      iex> add_offering_option(offering, %{field: value})
      {:ok, %OfferingOption{}}

      iex> add_offering_option(offering, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def add_offering_option(offering, attrs \\ %{}) do
    %OfferingOption{}
    |> OfferingOption.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:offering, offering)
    |> Repo.insert()
  end

  @doc """
  Updates a offering_option.

  ## Examples

      iex> update_offering_option(offering_option, %{field: new_value})
      {:ok, %OfferingOption{}}

      iex> update_offering_option(offering_option, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_offering_option(%OfferingOption{} = offering_option, attrs) do
    offering_option
    |> OfferingOption.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a offering_option.

  ## Examples

      iex> delete_offering_option(offering_option)
      {:ok, %OfferingOption{}}

      iex> delete_offering_option(offering_option)
      {:error, %Ecto.Changeset{}}

  """
  def delete_offering_option(%OfferingOption{} = offering_option) do
    Repo.delete(offering_option)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking offering_option changes.

  ## Examples

      iex> change_offering_option(offering_option)
      %Ecto.Changeset{data: %OfferingOption{}}

  """
  def change_offering_option(%OfferingOption{} = offering_option, attrs \\ %{}) do
    OfferingOption.changeset(offering_option, attrs)
  end
end
