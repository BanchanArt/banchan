defmodule Banchan.Studios do
  @moduledoc """
  The Studios context.
  """
  @dialyzer [
    {:nowarn_function, create_stripe_account: 0},
    :no_return
  ]

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
    %{studio | stripe_id: create_stripe_account()}
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
  List offerings offered by this studio. Will take into account visibility
  based on whether the current user is a member of the studio and whether the
  offering is published.

  ## Examples

      iex> list_studio_offerings(studio, current_studio_member?)
      [%Offering{}, %Offering{}, %Offering{}]
  """
  def list_studio_offerings(studio, current_user_member?) do
    Repo.all(
      from o in Ecto.assoc(studio, :offerings),
        where: ^current_user_member? or o.hidden == false,
        order_by: o.index,
        preload: [:options]
    )
  end

  @doc """
  Determine if a user is part of a studio.

  ## Examples

      iex> is_user_in_studio(user, studio)
      true
  """
  def is_user_in_studio(user, studio) do
    Repo.exists?(
      from us in "users_studios", where: us.user_id == ^user.id and us.studio_id == ^studio.id
    )
  end

  def get_onboarding_link(%Studio{} = studio, return_url, refresh_url) do
    {:ok, link} =
      Stripe.AccountLink.create(%{
        account: studio.stripe_id,
        type: "account_onboarding",
        return_url: return_url,
        refresh_url: refresh_url
      })

    link.url
  end

  def charges_enabled?(%Studio{} = studio, refresh \\ false) do
    if refresh do
      {:ok, acct} = Stripe.Account.retrieve(studio.stripe_id)

      if acct.charges_enabled != studio.stripe_charges_enabled do
        %{studio | stripe_charges_enabled: acct.charges_enabled}
        |> Repo.update!()
      end

      acct.charges_enabled
    else
      studio.stripe_charges_enabled
    end
  end

  def update_stripe_charges_enabled(account_id, charges_enabled) do
    from(s in Studio, where: s.stripe_id == ^account_id)
    |> Repo.update_all(set: [stripe_charges_enabled: charges_enabled])
  end

  defp create_stripe_account do
    # NOTE: I don't know why dialyzer complains about this. It works just fine.
    {:ok, acct} =
      Stripe.Account.create(%{
        type: "express",
        settings: %{payouts: %{schedule: %{interval: "manual"}}}
      })

    acct.id
  end
end
