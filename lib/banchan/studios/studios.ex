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
  require Logger

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Invoice
  alias Banchan.Notifications
  alias Banchan.Offerings.Offering
  alias Banchan.Repo
  alias Banchan.Studios.{Payout, Studio}

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

      iex> is_user_in_studio?(user, studio)
      true
  """
  def is_user_in_studio?(%User{id: user_id}, %Studio{id: studio_id}) do
    Repo.exists?(
      from us in "users_studios", where: us.user_id == ^user_id and us.studio_id == ^studio_id
    )
  end

  def get_onboarding_link!(%Studio{} = studio, return_url, refresh_url) do
    {:ok, link} =
      stripe_mod().create_account_link(%{
        account: studio.stripe_id,
        type: "account_onboarding",
        return_url: return_url,
        refresh_url: refresh_url
      })

    link.url
  end

  def get_banchan_balance!(%Studio{} = studio) do
    {:ok, stripe_balance} =
      stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id})

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
        join: c in assoc(i, :commission),
        left_join: p in assoc(i, :payout),
        where:
          c.studio_id == ^studio.id and
            i.status == :succeeded,
        group_by: [
          fragment("CASE WHEN s2.status = 'pending' OR s2.status = 'in_transit' THEN 'on_the_way'
                  WHEN s2.status = 'paid' THEN 'paid'
                  WHEN s2.status = 'failed' THEN 'failed'
                  WHEN c1.status = 'approved' AND c0.payout_id IS NULL THEN 'released'
                  ELSE 'held_back'
                END"),
          fragment("(c0.amount).currency"),
          fragment("(c0.tip).currency"),
          fragment("(c0.platform_fee).currency")
        ],
        select: %{
          status:
            type(
              fragment(
                "CASE WHEN s2.status = 'pending' OR s2.status = 'in_transit' THEN 'on_the_way'
                  WHEN s2.status = 'paid' THEN 'paid'
                  WHEN s2.status = 'failed' THEN 'failed'
                  WHEN c1.status = 'approved' AND c0.payout_id IS NULL THEN 'released'
                  ELSE 'held_back'
                END"
              ),
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
              fragment("(sum((c0.platform_fee).amount), (c0.platform_fee).currency)"),
              Money.Ecto.Composite.Type
            )
        }
      )
      |> Repo.all()

    {released, held_back, on_the_way, paid, failed} = get_net_values(results)

    available = get_released_available(stripe_available, released)

    %{
      stripe_available: stripe_available,
      stripe_pending: stripe_pending,
      held_back: held_back,
      released: released,
      on_the_way: on_the_way,
      paid: paid,
      failed: failed,
      available: available
    }
  end

  defp get_net_values(results) do
    Enum.reduce(results, {[], [], [], [], []}, fn %{status: status} = res,
                                                  {released, held_back, on_the_way, paid, failed} ->
      net = Money.subtract(Money.add(res.charged, res.tips), res.fees)

      case status do
        "released" ->
          {[net | released], held_back, on_the_way, paid, failed}

        "held_back" ->
          {released, [net | held_back], on_the_way, paid, failed}

        "on_the_way" ->
          {released, held_back, [net | on_the_way], paid, failed}

        "paid" ->
          {released, held_back, on_the_way, [net | paid], failed}

        "failed" ->
          {released, held_back, on_the_way, paid, [net | failed]}
      end
    end)
  end

  defp get_released_available(stripe_available, released) do
    Enum.map(released, fn rel ->
      from_stripe =
        Enum.find(stripe_available, Money.new(0, rel.currency), &(&1.currency == rel.currency))

      cond do
        from_stripe.amount >= rel.amount ->
          rel

        from_stripe.amount < rel.amount ->
          from_stripe

        true ->
          Money.new(0, rel.currency)
      end
    end)
  end

  def payout_studio(%Studio{} = studio) do
    {:ok, balance} =
      stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id})

    try do
      # TODO: notifications!
      {:ok, Enum.map(balance.available, &payout_available!(studio, &1))}
    rescue
      e in Stripe.Error ->
        Logger.error("Stripe error during payout: #{e.message}")
        {:error, e.user_message}
    catch
      {:error, err} ->
        {:error, err}
    end
  end

  defp payout_available!(%Studio{} = studio, avail) do
    avail = Money.new(avail.amount, String.to_atom(String.upcase(avail.currency)))

    if avail.amount > 0 do
      {invoice_ids, invoice_count, total} = invoice_details(studio, avail)

      if total.amount > 0 do
        create_payout!(studio, invoice_ids, invoice_count, total)
        total
      else
        Money.new(0, avail.currency)
      end
    else
      Money.new(0, avail.currency)
    end
  end

  defp invoice_details(%Studio{} = studio, avail) do
    currency_str = Atom.to_string(avail.currency)
    now = NaiveDateTime.utc_now()

    from(i in Invoice,
      join: c in assoc(i, :commission),
      where:
        c.studio_id == ^studio.id and i.status == :succeeded and is_nil(i.payout_id) and
          fragment("(c0.amount).currency = ?::char(3)", ^currency_str) and
          i.payout_available_on < ^now,
      order_by: {:asc, i.updated_at}
    )
    |> Repo.all()
    |> Enum.reduce_while({[], 0, Money.new(0, avail.currency)}, fn invoice,
                                                                   {invoice_ids, invoice_count,
                                                                    total} = acc ->
      invoice_total = Money.subtract(Money.add(invoice.amount, invoice.tip), invoice.platform_fee)

      if invoice_total.amount + total.amount > avail.amount do
        {:halt, acc}
      else
        {:cont, {[invoice.id | invoice_ids], invoice_count + 1, Money.add(total, invoice_total)}}
      end
    end)
  end

  defp create_payout!(%Studio{} = studio, invoice_ids, invoice_count, %Money{} = total) do
    {:ok, stripe_payout} =
      case stripe_mod().create_payout(
             %{
               amount: total.amount,
               currency: String.downcase(Atom.to_string(total.currency)),
               statement_descriptor: "banchan.art payout"
             },
             headers: %{"Stripe-Account" => studio.stripe_id}
           ) do
        {:ok, stripe_payout} ->
          {:ok, stripe_payout}

        {:error, %Stripe.Error{} = error} ->
          # NOTE: This will get rescued further up for a proper {:error, err} return.
          raise error
      end

    # TODO: This is racy af
    Repo.transaction(fn ->
      case %Payout{
             stripe_payout_id: stripe_payout.id,
             status: String.to_atom(stripe_payout.status),
             amount: total,
             studio_id: studio.id
           }
           |> Repo.insert(returning: [:id]) do
        {:ok, payout} ->
          case from(i in Invoice,
                 where: i.id in ^invoice_ids
               )
               |> Repo.update_all(set: [payout_id: payout.id]) do
            {^invoice_count, _} ->
              :ok

            {unexpected_count, _} ->
              # TODO: OK BUT WHY
              Logger.error(%{
                message:
                  "Wrong number of Invoice rows updated after payout (expected: #{invoice_count}, actual: #{unexpected_count})",
                error: %{}
              })

              cancel_payout!(studio, stripe_payout.id)

              # NOTE: This will get caught further up for a proper {:error, err} return.
              throw({:error, "Payout failed due to an internal error."})
          end

        {:error, err} ->
          Logger.error(%{message: "Failed to update database after payout", error: err})

          cancel_payout!(studio, stripe_payout.id)

          # NOTE: This will get caught further up for a proper {:error, err} return.
          throw({:error, "Payout failed due to an internal error."})
      end
    end)
  end

  defp cancel_payout!(%Studio{} = studio, payout_id) do
    case stripe_mod().cancel_payout(payout_id,
           headers: %{"Stripe-Account" => studio.stripe_id}
         ) do
      {:ok, _} ->
        :ok

      {:error, %Stripe.Error{} = err} ->
        raise err
    end
  end

  def process_payout_updated!(payout) do
    from(p in Payout,
      where: p.stripe_payout_id == ^payout.id
    )
    |> Repo.update_all(
      set: [
        status: String.to_atom(payout.status),
        failure_code: payout.failure_code,
        failure_message: payout.failure_message
      ]
    )

    :ok
  end

  def charges_enabled?(%Studio{} = studio, refresh \\ false) do
    if refresh do
      {:ok, acct} = stripe_mod().retrieve_account(studio.stripe_id)

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
      stripe_mod().create_account(%{
        type: "express",
        settings: %{payouts: %{schedule: %{interval: "manual"}}},
        # TODO: this should only be done for _international_ accounts.
        # tos_acceptance: %{
        #   service_agreement: "recipient"
        # },
        business_profile: %{
          # Digital Media
          mcc: "7333",
          url: studio_url
        }
      })

    acct.id
  end

  defp stripe_mod() do
    Application.get_env(:banchan, :stripe_mod)
  end
end
