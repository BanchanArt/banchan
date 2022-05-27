defmodule Banchan.Studios do
  @moduledoc """
  The Studios context.
  """
  @dialyzer [
    {:nowarn_function, create_stripe_account: 1},
    :no_return
  ]

  @pubsub Banchan.PubSub

  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Commissions.{Commission, Invoice}
  alias Banchan.Notifications
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

  def get_offering_by_type!(%Studio{} = studio, type) do
    Repo.get_by!(Offering, type: type, studio_id: studio.id)
  end

  @doc """
  Updates the studio profile fields.
  """
  def update_studio_profile(_, false, _) do
    {:error, :unauthorized}
  end

  def update_studio_profile(%Studio{} = studio, _, attrs) do
    studio
    |> Studio.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates a new studio.

  ## Examples

      iex> new_studio(studio, %{handle: ..., name: ..., ...})
      {:ok, %Studio{}}
  """
  def new_studio(%Studio{artists: artists} = studio, url, attrs) do
    changeset = studio |> Studio.changeset(attrs)

    changeset =
      if changeset.valid? do
        %{changeset | data: %{studio | stripe_id: create_stripe_account(url)}}
      else
        changeset
      end

    case changeset |> Repo.insert() do
      {:ok, studio} ->
        Repo.transaction(fn ->
          Enum.each(artists, &Notifications.subscribe_user!(&1, studio))
        end)

        {:ok, studio}

      {:error, err} ->
        {:error, err}
    end
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
  def list_studios_for_user(%User{} = user) do
    Repo.all(Ecto.assoc(user, :studios))
  end

  @doc """
  List members who are part of a studio

  ## Examples

      iex> list_studio_members(studio)
      [%User{}, %User{}, %User{}]
  """
  def list_studio_members(%Studio{} = studio) do
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
  def list_studio_offerings(%Studio{} = studio, current_user_member?) do
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
  def is_user_in_studio(%User{id: user_id}, %Studio{id: studio_id}) do
    Repo.exists?(
      from us in "users_studios", where: us.user_id == ^user_id and us.studio_id == ^studio_id
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

  defp get_stripe_balance!(%Studio{} = studio) do
    {:ok, balance} = Stripe.Balance.retrieve(headers: %{"Stripe-Account" => studio.stripe_id})
    balance
  end

  def get_banchan_balance!(%Studio{} = studio) do
    stripe_balance = get_stripe_balance!(studio)

    stripe_available =
      stripe_balance.available
      |> Enum.map(&Money.new(&1.amount, String.to_atom(String.upcase(&1.currency))))
      |> Enum.sort()

    stripe_pending =
      stripe_balance.pending
      |> Enum.map(&Money.new(&1.amount, String.to_atom(String.upcase(&1.currency))))
      |> Enum.sort()

    results =
      from(i in Invoice,
        join: c in Commission,
        where:
          i.commission_id == c.id and
            c.studio_id == ^studio.id and
            i.status == :succeeded,
        group_by: [
          fragment("case when c1.status = 'approved' then 'approved' else 'pending' end"),
          fragment("(c0.amount).currency"),
          fragment("(c0.tip).currency"),
          fragment("(c0.platform_fee).currency")
        ],
        select: %{
          comm_status:
            type(
              fragment("case when c1.status = 'approved' then 'approved' else 'pending' end"),
              :string
            ),
          charged:
            type(
              fragment("(sum((c0.amount).amount), (c0.amount).currency)"),
              Money.Ecto.Composite.Type
            ),
          tips:
            type(
              fragment("(sum((c0.tip).amount), (c0.tip).currency)"),
              Money.Ecto.Composite.Type
            ),
          fees:
            type(
              fragment(
                "(sum((c0.platform_fee).amount), (c0.platform_fee).currency)"
              ),
              Money.Ecto.Composite.Type
            )
        }
      )
      |> Repo.all()

      {released, held_back} = results
      |> Enum.split_with(& &1.comm_status == "approved")

    %{
      stripe_available: stripe_available,
      stripe_pending: stripe_pending,
      held_back: held_back,
      released: released
    }
  end

  def payout_studio!(%Studio{} = studio) do
    balance = get_stripe_balance!(studio)

    Enum.each(balance.available, fn avail ->
      if avail.amount > 0 do
        {:ok, _} =
          Stripe.Payout.create(
            %{
              amount: avail.amount,
              currency: avail.currency,
              statement_descriptor: "Banchan Art"
            },
            headers: %{"Stripe-Account" => studio.stripe_id}
          )
      end
    end)

    :ok
  end

  def charges_enabled?(%Studio{} = studio, refresh \\ false) do
    if refresh do
      {:ok, acct} = Stripe.Account.retrieve(studio.stripe_id)

      if acct.charges_enabled != studio.stripe_charges_enabled do
        update_stripe_state(studio.stripe_id, acct)
      end

      acct.charges_enabled
    else
      studio.stripe_charges_enabled
    end
  end

  def update_stripe_state(account_id, account) do
    ret =
      from(s in Studio, where: s.stripe_id == ^account_id)
      |> Repo.update_all(
        set: [
          stripe_charges_enabled: account.charges_enabled,
          stripe_details_submitted: account.details_submitted
        ]
      )

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "studio_stripe_state:#{account_id}",
      %Phoenix.Socket.Broadcast{
        topic: "studio_stripe_state:#{account_id}",
        event: "charges_state_changed",
        payload: account.charges_enabled
      }
    )

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "studio_stripe_state:#{account_id}",
      %Phoenix.Socket.Broadcast{
        topic: "studio_stripe_state:#{account_id}",
        event: "details_submitted_changed",
        payload: account.details_submitted
      }
    )

    ret
  end

  def subscribe_to_stripe_state(%Studio{stripe_id: stripe_id}) do
    Phoenix.PubSub.subscribe(@pubsub, "studio_stripe_state:#{stripe_id}")
  end

  defp create_stripe_account(studio_url) do
    # NOTE: I don't know why dialyzer complains about this. It works just fine.
    {:ok, acct} =
      Stripe.Account.create(%{
        type: "express",
        settings: %{payouts: %{schedule: %{interval: "manual"}}},
        # TODO: this should only be done for _international_ accounts.
        # tos_acceptance: %{
        #   service_agreement: "recipient"
        # },
        business_profile: %{
          # Digital Media
          mcc: "7333",
          # Just to make our lives easier.
          url: String.replace(studio_url, "http://localhost:4000", "https://banchan.art")
        }
      })

    acct.id
  end
end
