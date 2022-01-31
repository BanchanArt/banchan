defmodule Banchan.Studios do
  @moduledoc """
  The Studios context.
  """

  import Ecto.Query, warn: false

  alias Banchan.Offerings.Offering
  alias Banchan.Repo
  alias Banchan.Studios.Studio

  @doc """
  Gets a studio by its handle.

  ## Examples

      iex> get_studio_by_handle!("foo")
      %Studio{}

      iex> get_studio_by_handle!("unknown")
      Exception Thrown

  """
  def get_studio_by_handle!(handle) when is_binary(handle) do
    Repo.get_by!(Studio, handle: handle)
  end

  def get_offering_by_type!(studio, type) do
    Repo.get_by!(Offering, type: type, studio_id: studio.id)
  end

  @doc """
  Updates the studio profile fields.

  ## Examples

      iex> update_studio_profile(studio, %{handle: ..., name: ..., ...})
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

      iex> new_studio(studio, %{handle: ..., name: ..., ...})
      {:ok, %Studio{}}
  """
  def new_studio(studio, attrs) do
    studio
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
  def list_studio_offerings(studio, current_user_member?) do
    Repo.all(
      from o in Ecto.assoc(studio, :offerings),
        where: ^current_user_member? or o.show,
        order_by: o.index,
        preload: [:options]
    )
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
