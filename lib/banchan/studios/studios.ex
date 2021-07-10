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

  @doc """
  List all studios

  ## Examples

      iex> list_studios()
      [%Studio{}, %Studio{}, %Studio{}, ...]
  """
  def list_studios do
    Repo.all(Studio)
  end

  @doc """
  List studios belonging to a user

  ## Examples

      iex> list_studios_for_user(user)
      [%Studio{}, %Studio{}, %Studio{}]
  """
  def list_studios_for_user(user) do
    Repo.all(Ecto.assoc(user, :studios))
  end

  @doc """
  Determine if a user is part of a studio. If the studio is omitted, returns
  true if the user is part of ANY studio.

  ## Examples

      iex> is_user_in_studio(user, studio)
      true
  """
  def is_user_in_studio(user, studio \\ false) do
    if studio do
      Repo.exists?(
        from us in "users_studios", where: us.user_id == ^user.id and us.studio_id == ^studio.id
      )
    else
      Repo.exists?(from us in "users_studios", where: us.user_id == ^user.id)
    end
  end
end
