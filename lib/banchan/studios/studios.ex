defmodule Banchan.Studios do
  @moduledoc """
  The Studios context.
  """

  import Ecto.Query, warn: false

  alias Banchan.Repo
  alias Banchan.Studios.{Offering, Studio}

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

  def get_offering_by_type!(studio, type) do
    Repo.get_by!(Offering, [type: type, studio_id: studio.id])
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
    %Studio{artists: [user]}
    |> Studio.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:artists, [user])
    |> Repo.insert()
  end

  def new_offering(studio, attrs) do
    %Offering{studio_id: studio.id}
    |> Offering.changeset(attrs)
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
  List members who are part of a studio

  ## Examples

      iex> list_studio_members(studio)
      [%User{}, %User{}, %User{}]
  """
  def list_studio_members(studio) do
    Repo.all(Ecto.assoc(studio, :artists))
  end

  @doc """
  List offerings offered by this studio

  ## Examples

      iex> list_studio_offerings(studio)
      [%Offering{}, %Offering{}, %Offering{}]
  """
  def list_studio_offerings(studio) do
    Repo.all(from o in Ecto.assoc(studio, :offerings), order_by: o.index)
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
