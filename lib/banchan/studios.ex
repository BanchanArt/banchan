defmodule Banchan.Studios do
  @moduledoc """
  The Studios context.
  """

  import Ecto.Query, warn: false

  alias Banchan.Repo
  alias Banchan.Studios.Studio

  @doc """
  Gets a studio by its slug.

  ## Examples

      iex> get_studio_by_slug!("foo")
      %Studio{}

      iex> get_studio_by_slug!("unknown")
      Exception Thrown

  """
  def get_studio_by_slug!(slug) when is_binary(slug) do
    Repo.get_by!(Studio, slug: slug)
  end

  @doc """
  Updates the studio profile fields.

  ## Examples

      iex> update_studio_profile(studio, %{slug: ..., name: ..., ...})
      {:ok, %Studio{}}

  """
  def update_studio_profile(user, attrs) do
    user
    |> Studio.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates a new studio.

  ## Examples

      iex> new_studio(studio, %{slug: ..., name: ..., ...})
      {:ok, %Studio{}}
  """
  def new_studio(user, attrs) do
    user
    |> Studio.changeset(attrs)
    |> Repo.insert()
  end
end
