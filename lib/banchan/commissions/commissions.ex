defmodule Banchan.Commissions do
  @moduledoc """
  The Commissions context.
  """

  import Ecto.Query, warn: false
  alias Banchan.Repo

  alias Banchan.Commissions.Commission

  @doc """
  Returns the list of commissions.

  ## Examples

      iex> list_commissions()
      [%Commission{}, ...]

  """
  def list_commissions do
    Repo.all(Commission)
  end

  @doc """
  Gets a single commission.

  Raises `Ecto.NoResultsError` if the Commission does not exist.

  ## Examples

      iex> get_commission!(123)
      %Commission{}

      iex> get_commission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_commission!(id), do: Repo.get!(Commission, id)

  @doc """
  Creates a commission.

  ## Examples

      iex> create_commission(%{field: value})
      {:ok, %Commission{}}

      iex> create_commission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_commission(attrs \\ %{}) do
    %Commission{}
    |> Commission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a commission.

  ## Examples

      iex> update_commission(commission, %{field: new_value})
      {:ok, %Commission{}}

      iex> update_commission(commission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_commission(%Commission{} = commission, attrs) do
    commission
    |> Commission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a commission.

  ## Examples

      iex> delete_commission(commission)
      {:ok, %Commission{}}

      iex> delete_commission(commission)
      {:error, %Ecto.Changeset{}}

  """
  def delete_commission(%Commission{} = commission) do
    Repo.delete(commission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking commission changes.

  ## Examples

      iex> change_commission(commission)
      %Ecto.Changeset{data: %Commission{}}

  """
  def change_commission(%Commission{} = commission, attrs \\ %{}) do
    Commission.changeset(commission, attrs)
  end
end
