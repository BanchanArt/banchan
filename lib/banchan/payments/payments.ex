defmodule Banchan.Payments do
  @moduledoc """
  Context module for payments-related functionality: invoicing, payment
  processing, refunds, payouts, etc. Basically, everything Stripe-related.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, Event}
  alias Banchan.Payments.{Invoice, Notifications, Payout}
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias Banchan.Workers.{ExpiredInvoicePurger, ExpiredInvoiceWarner}

  ## Events

  @pubsub Banchan.PubSub

  @doc """
  Subscribes the current process to payout-related events for this Studio.
  """
  def subscribe_to_payout_events(%Studio{} = studio) do
    Phoenix.PubSub.subscribe(@pubsub, "payout:#{studio.handle}")
  end

  @doc """
  Unsubscribes the current process from payout-related events for this Studio.
  """
  def unsubscribe_from_payout_events(%Studio{} = studio) do
    Phoenix.PubSub.unsubscribe(@pubsub, "payout:#{studio.handle}")
  end

  ## Getting/Listing

  @doc """
  Lists invoices.

  ## Options

    * `:commission` - The commission invoices should belong to.
    * `:with_statuses` - List of statuses to filter by.
  """
  def list_invoices(opts \\ []) do
    from(i in Invoice, as: :invoice)
    |> filter_commission(opts)
    |> filter_statuses(opts)
    |> Repo.all()
  end

  defp filter_commission(q, opts) do
    case Keyword.fetch(opts, :commission) do
      {:ok, %Commission{id: id}} ->
        q |> where([invoice: i], i.commission_id == ^id)

      :error ->
        q
    end
  end

  defp filter_statuses(q, opts) do
    case Keyword.fetch(opts, :with_statuses) do
      {:ok, statuses} ->
        q |> where([invoice: i], i.status in ^statuses)

      :error ->
        q
    end
  end

  @doc """
  True if a given invoice has been paid. Expects an already-loaded invoice
  with the latest data.
  """
  def invoice_paid?(%Invoice{status: status}), do: status in [:succeeded, :released]

  @doc """
  True if a given invoice is in a "finished" state.
  """
  def invoice_finished?(%Invoice{status: status}),
    do: status in [:succeeded, :released, :refunded, :expired]

  @doc """
  Gets account balance stats for a studio, including how much is available on
  Stripe, how much has been released and available for payout, etc.
  """
  def get_banchan_balance(%Studio{} = studio) do
    with {:ok, stripe_balance} <-
           stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id}) do
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
          left_join: p in assoc(i, :payouts),
          where:
            c.studio_id == ^studio.id and
              (i.status == :succeeded or i.status == :released),
          group_by: [
            fragment("CASE WHEN ? = 'pending' OR ? = 'in_transit' THEN 'on_the_way'
                  WHEN ? = 'paid' THEN 'paid'
                  WHEN ? = 'released' THEN 'released'
                  ELSE 'held_back'
                END", p.status, p.status, p.status, i.status),
            fragment("(?).currency", i.total_transferred)
          ],
          select: %{
            status:
              type(
                fragment("CASE WHEN ? = 'pending' OR ? = 'in_transit' THEN 'on_the_way'
                  WHEN ? = 'paid' THEN 'paid'
                  WHEN ? = 'released' THEN 'released'
                  ELSE 'held_back'
                END", p.status, p.status, p.status, i.status),
                :string
              ),
            final:
              type(
                fragment(
                  "(sum((?).amount), (?).currency)",
                  i.total_transferred,
                  i.total_transferred
                ),
                Money.Ecto.Composite.Type
              )
          }
        )
        |> Repo.all()

      {released, held_back, on_the_way, paid} = get_net_values(results)

      available = get_released_available(stripe_available, released)

      {:ok,
       %{
         stripe_available: stripe_available,
         stripe_pending: stripe_pending,
         held_back: held_back,
         released: released,
         on_the_way: on_the_way,
         paid: paid,
         available: available
       }}
    end
  end

  defp get_net_values(results) do
    Enum.reduce(results, {[], [], [], []}, fn %{status: status} = res,
                                              {released, held_back, on_the_way, paid} ->
      case status do
        "released" ->
          {[res.final | released], held_back, on_the_way, paid}

        "held_back" ->
          {released, [res.final | held_back], on_the_way, paid}

        "on_the_way" ->
          {released, held_back, [res.final | on_the_way], paid}

        "paid" ->
          {released, held_back, on_the_way, [res.final | paid]}
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
      end
    end)
  end

  @doc """
  Gets a specific payout with its actor and invoices preloaded.
  """
  def get_payout!(public_id) when is_binary(public_id) do
    from(p in Payout,
      where: p.public_id == ^public_id,
      preload: [:actor, [invoices: [:commission, :event]]]
    )
    |> Repo.one!()
  end

  @doc """
  Paginated view of payouts for a studio.
  """
  def list_payouts(%Studio{} = studio, page \\ 1) do
    from(
      p in Payout,
      where: p.studio_id == ^studio.id,
      order_by: {:desc, p.inserted_at}
    )
    |> Repo.paginate(page: page, page_size: 10)
  end

  ## Creation

  @doc """
  Creates a new invoice.
  """
  def invoice(%User{} = actor, %Commission{} = commission, drafts, event_data) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:checked_actor, fn _repo, _changes ->
      actor = Repo.reload(actor)

      if Studios.is_user_in_studio?(actor, %Studio{id: commission.studio_id}) ||
           Accounts.mod?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.run(:event, fn _repo, %{checked_actor: actor} ->
      Commissions.create_event(:comment, actor, commission, true, drafts, event_data)
    end)
    |> Ecto.Multi.insert(:invoice, fn %{event: event} ->
      %Invoice{
        client_id: commission.client_id,
        commission: commission,
        event: event
      }
      |> Invoice.creation_changeset(event_data)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{invoice: invoice, event: event, checked_actor: actor}} ->
        send_event_update!(event.id, actor)
        {:ok, invoice}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  defp send_event_update!(event_id, actor \\ nil) do
    event =
      from(e in Event,
        where: e.id == ^event_id,
        select: e,
        preload: [:actor, invoice: [], attachments: [:upload, :thumbnail, :preview]]
      )
      |> Repo.one!()

    commission =
      from(c in Commission, where: c.id == ^event.commission_id)
      |> Repo.one!()

    Commissions.Notifications.commission_event_updated(commission, event, actor)
  end

  @doc """
  Pays out a single Invoice.
  """
  def payout_invoice(%User{} = actor, %Studio{} = studio, %Invoice{} = invoice) do
    with {:ok, balance} <-
           stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id}) do
      avail =
        balance.available
        |> Enum.find(fn avail ->
          curr = avail.currency |> String.upcase() |> String.to_atom()
          curr == invoice.total_transferred.currency
        end)

      if avail.amount > 0 do
        create_payout(actor, studio, [invoice.id], 1, invoice.total_transferred)
      else
        {:error, :insufficient_funds}
      end
    end
    |> case do
      {:ok, invoice} ->
        {:ok, invoice}

      {:error, %Stripe.Error{} = e} ->
        Logger.error("Stripe error during payout: #{inspect(e)}")
        {:error, e}

      {:error, error} ->
        Logger.error("Internal error during payout: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Pays out a Studio for the full available and released amount.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def payout_studio(%User{} = actor, %Studio{} = studio) do
    with {:ok, balance} <-
           stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id}) do
      Repo.transaction(fn ->
        # NB(@zkat): We're not using Ecto.Multi here because we still want
        # to commit errored payouts that failed because of Stripe failures, so they show up for users.
        Enum.reduce_while(balance.available, {:ok, []}, fn avail, {:ok, acc} ->
          case payout_available(actor, studio, avail) do
            {:ok, nil} ->
              {:cont, {:ok, acc}}

            {:ok, payout} ->
              {:cont, {:ok, [payout | acc]}}

            {:error, error} ->
              {:halt, {:error, error}}
          end
        end)
      end)
      |> case do
        {:ok, {:ok, payouts}} ->
          {:ok, Enum.reverse(payouts)}

        {:ok, {:error, error}} ->
          {:error, error}

        {:error, error} ->
          {:error, error}
      end
    end
    |> case do
      {:ok, payouts} ->
        {:ok, payouts}

      {:error, %Stripe.Error{} = e} ->
        Logger.error("Stripe error during payout: #{inspect(e)}")
        {:error, e}

      {:error, error} ->
        Logger.error("Internal error during payout: #{inspect(error)}")
        {:error, error}
    end
  end

  defp payout_available(%User{} = actor, %Studio{} = studio, avail) do
    avail = Money.new(avail.amount, String.to_atom(String.upcase(avail.currency)))

    if avail.amount > 0 do
      with {:ok, {invoice_ids, invoice_count, total}} <- invoice_details(studio, avail) do
        if total.amount > 0 do
          create_payout(actor, studio, invoice_ids, invoice_count, total)
        else
          {:ok, nil}
        end
      end
    else
      {:ok, nil}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp invoice_details(%Studio{} = studio, avail) do
    currency_str = Atom.to_string(avail.currency)
    now = NaiveDateTime.utc_now()

    from(i in Invoice,
      join: c in assoc(i, :commission),
      left_join: p in assoc(i, :payouts),
      where:
        c.studio_id == ^studio.id and i.status == :released and
          (is_nil(p.id) or p.status not in [:pending, :in_transit, :paid]) and
          fragment("(?).currency = ?::char(3)", i.total_transferred, ^currency_str) and
          i.payout_available_on <= ^now,
      order_by: {:asc, i.updated_at}
    )
    |> Repo.all()
    |> Enum.reduce_while({:ok, {[], 0, Money.new(0, avail.currency)}}, fn invoice,
                                                                          {:ok,
                                                                           {invoice_ids,
                                                                            invoice_count,
                                                                            total}} = acc ->
      invoice_total = invoice.total_transferred

      case stripe_mod().retrieve_charge(invoice.stripe_charge_id) do
        {:ok, charge} ->
          cond do
            charge.balance_transaction.status != "available" ->
              {:cont, acc}

            invoice_total.amount + total.amount > avail.amount ->
              # NB(@zkat): This should _generally_ not happen, but may as well
              # check for it.
              {:halt, acc}

            true ->
              {:cont,
               {:ok,
                {[invoice.id | invoice_ids], invoice_count + 1, Money.add(total, invoice_total)}}}
          end

        {:error, stripe_err} ->
          {:halt, {:error, stripe_err}}
      end
    end)
  end

  defp create_payout(
         %User{} = actor,
         %Studio{} = studio,
         invoice_ids,
         invoice_count,
         %Money{} = total
       ) do
    Ecto.Multi.new()
    |> Ecto.Multi.all(:invoices, from(i in Invoice, where: i.id in ^invoice_ids))
    |> Ecto.Multi.insert(
      :payout,
      fn %{invoices: invoices} ->
        %Payout{
          amount: total,
          studio_id: studio.id,
          actor_id: actor && actor.id,
          invoices: invoices
        }
      end,
      returning: true
    )
    |> Ecto.Multi.one(:invoice_count, fn %{payout: payout} ->
      from(p in Payout,
        where: p.id == ^payout.id,
        join: i in assoc(p, :invoices),
        select: count(i.id)
      )
    end)
    |> Ecto.Multi.run(:check_invoice_count, fn _, %{invoice_count: actual_count} ->
      if actual_count == invoice_count do
        {:ok, true}
      else
        Logger.error(
          "Wrong number of invoices associated with new Payout (expected: #{invoice_count}, actual: ${actual_count}"
        )

        {:error, :invoice_count_mismatch}
      end
    end)
    |> Ecto.Multi.run(:updated_payout, fn _repo, %{payout: payout} ->
      case create_stripe_payout(studio, total) do
        {:ok, stripe_payout} ->
          process_payout_updated!(stripe_payout, payout.id)

        {:error, err} ->
          Logger.error("Failed to create Stripe payout: #{inspect(err)}")

          # NB(@zkat): We still return {:ok, payout} here, so folks can
          # actually see the failed payout on their dashboards when calling
          # out to stripe failed.
          with {:ok, _} <-
                 process_payout_updated!(
                   %Stripe.Payout{
                     status: :failed,
                     arrival_date: DateTime.utc_now() |> DateTime.to_unix()
                   },
                   payout.id
                 ) do
            {:ok, err}
          end
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_payout: %Stripe.Error{} = err}} ->
        {:error, err}

      {:ok, %{updated_payout: payout}} ->
        Notifications.payout_sent(payout)
        {:ok, payout}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  defp create_stripe_payout(%Studio{} = studio, %Money{} = total) do
    stripe_mod().create_payout(
      %{
        amount: total.amount,
        currency: String.downcase(Atom.to_string(total.currency)),
        statement_descriptor: "Banchan Art Payout"
      },
      headers: %{"Stripe-Account" => studio.stripe_id}
    )
  end

  ## Updating/Editing

  @doc """
  Releases a payment.
  """
  def release_payment(%User{} = actor, %Commission{} = commission, %Invoice{} = invoice) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:actor, fn _, _ ->
      Commissions.check_actor_edit_access(actor, commission)
    end)
    |> Ecto.Multi.update_all(
      :invoices,
      fn %{actor: actor} ->
        from(i in Invoice,
          join: c in assoc(i, :commission),
          where: i.id == ^invoice.id and c.client_id == ^actor.id and i.status == :succeeded
        )
      end,
      set: [status: :released]
    )
    |> Ecto.Multi.run(:check_updated_count, fn _, %{invoices: {n, _}} ->
      case n do
        0 ->
          {:error, :invalid_invoice_status}

        1 ->
          {:ok, true}

        n when is_integer(n) ->
          {:error, :updated_too_many_invoices}
      end
    end)
    |> Ecto.Multi.one(:event, fn _ ->
      from(e in Event,
        where: e.id == ^invoice.event_id,
        select: e,
        preload: [:actor, invoice: [], attachments: [:upload, :thumbnail, :preview]]
      )
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{event: event, actor: actor}} ->
        Commissions.Notifications.invoice_released(commission, event, actor)
        Commissions.Notifications.commission_event_updated(commission, event, actor)
        {:ok, event}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Processes a client payment
  """
  def process_payment(%User{id: user_id}, _, %Commission{client_id: client_id}, _, _)
      when user_id != client_id do
    {:error, :unauthorized}
  end

  def process_payment(
        %User{} = actor,
        %Event{invoice: %Invoice{amount: amount} = invoice} = event,
        %Commission{} = commission,
        uri,
        tip
      ) do
    items = [
      %{
        price_data: %{
          product_data: %{
            name: "Commission Invoice Payment"
          },
          unit_amount: amount.amount,
          currency: String.downcase(to_string(amount.currency)),
          tax_behavior: "exclusive"
        },
        quantity: 1
      },
      %{
        price_data: %{
          product_data: %{
            name: "Extra Tip"
          },
          unit_amount: tip.amount,
          currency: String.downcase(to_string(tip.currency)),
          tax_behavior: "exclusive"
        },
        quantity: 1
      }
    ]

    Ecto.Multi.new()
    |> Ecto.Multi.one(
      :studio_info,
      from(s in Studio,
        where: s.id == ^commission.studio_id,
        select: {s.stripe_id, s.platform_fee}
      )
    )
    |> Ecto.Multi.run(:platform_fee_amount, fn _, %{studio_info: {_, platform_fee}} ->
      {:ok, Money.multiply(Money.add(amount, tip), platform_fee)}
    end)
    |> Ecto.Multi.run(:session, fn _,
                                   %{
                                     studio_info: {stripe_id, _},
                                     platform_fee_amount: platform_fee
                                   } ->
      with transfer_amt <- amount |> Money.add(tip) |> Money.subtract(platform_fee) do
        stripe_mod().create_session(%{
          payment_method_types: ["card"],
          mode: "payment",
          cancel_url: uri,
          success_url: uri,
          line_items: items,
          automatic_tax: %{
            enabled: true
          },
          payment_intent_data: %{
            transfer_data: %{
              amount: transfer_amt.amount,
              destination: stripe_id
            }
          }
        })
      end
    end)
    |> Ecto.Multi.update(:updated_invoice, fn %{
                                                session: session,
                                                platform_fee_amount: platform_fee
                                              } ->
      invoice
      |> Invoice.submit_changeset(%{
        tip: tip,
        platform_fee: platform_fee,
        stripe_session_id: session.id,
        checkout_url: session.url,
        status: :submitted
      })
    end)
    |> Ecto.Multi.run(:finalize, fn _, _ ->
      send_event_update!(event.id, actor)
      {:ok, true}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{session: session}} ->
        {:ok, session.url}

      {:error, _, error, _} ->
        Logger.error("Failed to process payment: #{inspect(error)}")
        {:error, :payment_failed}
    end
  end

  @doc """
  Webhook handler for when a payment has been successfully processed by Stripe.
  """
  def process_payment_succeeded!(session) do
    {:ok,
     %{charges: %{data: [%{id: charge_id, balance_transaction: txn_id, transfer: transfer}]}}} =
      stripe_mod().retrieve_payment_intent(session.payment_intent, %{}, [])

    {:ok, %{created: paid_on, available_on: available_on, amount: amt, currency: curr}} =
      stripe_mod().retrieve_balance_transaction(txn_id, [])

    {:ok, transfer} = stripe_mod().retrieve_transfer(transfer)

    total_charged = Money.new(amt, String.to_atom(String.upcase(curr)))
    final_transfer_txn = transfer.destination_payment.balance_transaction

    total_transferred =
      Money.new(
        final_transfer_txn.amount,
        String.to_atom(String.upcase(final_transfer_txn.currency))
      )

    {:ok, paid_on} = DateTime.from_unix(paid_on)
    {:ok, available_on} = DateTime.from_unix(available_on)

    {:ok, _} =
      Repo.transaction(fn ->
        {1, [{invoice, country}]} =
          from(i in Invoice,
            join: c in assoc(i, :commission),
            join: s in assoc(c, :studio),
            where: i.stripe_session_id == ^session.id,
            select: {i, s.country}
          )
          |> Repo.update_all(
            set: [
              status: :succeeded,
              payout_available_on: available_on,
              paid_on: paid_on,
              total_charged: total_charged,
              total_transferred: total_transferred,
              stripe_charge_id: charge_id
            ]
          )

        # Start the Doomsday Clock.
        purge_on = DateTime.utc_now() |> DateTime.add(max_payment_age(country))
        {:ok, _job} = ExpiredInvoicePurger.schedule_purge(invoice, purge_on)

        warn_on = purge_on |> DateTime.add(-1 * 60 * 60 * 72)
        {:ok, _job} = ExpiredInvoiceWarner.schedule_warning(invoice, warn_on)

        event = Repo.get!(Event, invoice.event_id)
        client = Repo.reload!(%User{id: invoice.client_id})
        commission = Repo.reload!(%Commission{id: event.commission_id})

        Commissions.create_event(
          :payment_processed,
          client,
          commission,
          true,
          [],
          %{
            amount: invoice.amount |> Money.add(invoice.tip)
          }
        )

        if client.email do
          Notifications.send_receipt(invoice, client, commission)
        end

        send_event_update!(invoice.event_id)
      end)

    :ok
  end

  @doc """
  Webhook handler for when a payment has been expired by a Studio member.
  """
  def process_payment_expired!(session) do
    # NOTE: This will crash (intentionally) if we try to expire an
    # already-succeeded payment. This should never happen, though, because it
    # doesn't make sense that Stripe would tell us that a payment succeeded
    # then tell us it's expired. So this crash is a good just-in-case.
    {1, [invoice]} =
      from(i in Invoice,
        where: i.stripe_session_id == ^session.id and i.status != :succeeded,
        select: i
      )
      |> Repo.update_all(set: [status: :expired])

    send_event_update!(invoice.event_id)
  end

  @doc """
  Expires a payment, preventing the client from being able to complete their
  session, if it's still active.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def expire_payment(
        %User{} = actor,
        %Invoice{} = invoice
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:invoice, fn _, _ ->
      {:ok, invoice |> Repo.reload() |> Repo.preload(:commission)}
    end)
    |> Ecto.Multi.run(:actor, fn _, %{invoice: invoice} ->
      actor = actor |> Repo.reload()

      if Studios.is_user_in_studio?(actor, %Studio{id: invoice.commission.studio_id}) ||
           Accounts.mod?(actor) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.run(:updated_invoice, fn _, %{invoice: invoice} ->
      case invoice do
        %Invoice{id: id, stripe_session_id: nil, status: :pending} ->
          # NOTE: This will crash (intentionally) if we try to expire an already-succeeded payment.
          {1, [invoice]} =
            from(i in Invoice, where: i.id == ^id and i.status != :succeeded, select: i)
            |> Repo.update_all(set: [status: :expired])

          send_event_update!(invoice.event_id)
          {:ok, invoice}

        %Invoice{stripe_session_id: session_id, status: :submitted} when session_id != nil ->
          # NOTE: We don't manually expire the invoice in the database here. That's
          # handled by process_payment_expired!/1 when the webhook fires.
          with {:ok, _} <- stripe_mod().expire_payment(session_id) do
            {:ok, invoice}
          end

        _ ->
          {:error, :invalid_state}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_invoice: invoice}} ->
        {:ok, invoice}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Refunds a payment that hasn't been released yet.
  """
  def refund_payment(%User{} = actor, %Invoice{} = invoice) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:invoice, fn _, _ ->
      {:ok, invoice |> Repo.reload() |> Repo.preload(:commission)}
    end)
    |> Ecto.Multi.run(:actor, fn _, %{invoice: invoice} ->
      actor = actor |> Repo.reload()

      if Accounts.has_roles?(actor, [:system, :admin, :mod]) ||
           Studios.is_user_in_studio?(actor, %Studio{id: invoice.commission.studio_id}) do
        {:ok, actor}
      else
        {:error, :unauthorized}
      end
    end)
    |> Ecto.Multi.run(:refund, fn _, %{actor: actor, invoice: invoice} ->
      if invoice.status != :succeeded do
        Logger.error(
          "Attempted to refund an invoice that wasn't :succeeded. Invoice: #{inspect(invoice)}"
        )

        {:error, :invoice_not_refundable}
      else
        process_refund_payment(actor, invoice)
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{refund: refund}} ->
        {:ok, refund}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  defp process_refund_payment(%User{} = actor, %Invoice{} = invoice) do
    case refund_payment_on_stripe(invoice) do
      {:ok, %Stripe.Refund{status: "failed"} = refund} ->
        Logger.error("Refund failed: #{inspect(refund)}")
        process_refund_updated(actor, refund, invoice.id, actor.id)

      {:ok, %Stripe.Refund{status: "canceled"} = refund} ->
        Logger.error("Refund canceled: #{inspect(refund)}")
        process_refund_updated(actor, refund, invoice.id, actor.id)

      {:ok, %Stripe.Refund{status: "requires_action"} = refund} ->
        Logger.info("Refund requires action: #{inspect(refund)}")
        # This should eventually succeed asynchronously.
        process_refund_updated(actor, refund, invoice.id, actor.id)

      {:ok, %Stripe.Refund{status: "succeeded"} = refund} ->
        process_refund_updated(actor, refund, invoice.id, actor.id)

      {:ok, %Stripe.Refund{status: "pending"} = refund} ->
        process_refund_updated(actor, refund, invoice.id, actor.id)

      {:error, %Stripe.Error{} = err} ->
        {:error, err}
    end
  end

  defp refund_payment_on_stripe(%Invoice{stripe_charge_id: charge_id}) do
    # https://stripe.com/docs/connect/destination-charges#issuing-refunds
    case stripe_mod().create_refund(
           %{
             charge: charge_id,
             reverse_transfer: true,
             refund_application_fee: true
           },
           []
         ) do
      {:ok, refund} ->
        {:ok, refund}

      {:error, err} ->
        Logger.error("Refund failed: #{inspect(err)}")
        {:error, err}
    end
  end

  @doc """
  Webhook handler for when a Stripe refund has been updated.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def process_refund_updated(
        %User{} = actor,
        %Stripe.Refund{} = refund,
        invoice_id,
        refunded_by_id \\ nil
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:event, fn _, _ ->
      assignments =
        case refund.status do
          "succeeded" ->
            [
              status: :refunded,
              refund_status: :succeeded,
              stripe_refund_id: refund.id,
              refund_failure_reason: nil
            ]

          "failed" ->
            [
              refund_status: :failed,
              stripe_refund_id: refund.id,
              refund_failure_reason: refund.failure_reason
            ]

          "canceled" ->
            [refund_status: :canceled, stripe_refund_id: refund.id, refund_failure_reason: nil]

          "pending" ->
            [refund_status: :pending, stripe_refund_id: refund.id, refund_failure_reason: nil]

          "requires_action" ->
            [
              refund_status: :requires_action,
              stripe_refund_id: refund.id,
              refund_failure_reason: nil
            ]
        end

      assignments =
        if refunded_by_id do
          assignments ++ [refunded_by_id: refunded_by_id]
        else
          assignments
        end

      update_res =
        if is_nil(invoice_id) do
          from(i in Invoice,
            where: i.status == :succeeded and i.stripe_refund_id == ^refund.id,
            select: i.id
          )
        else
          from(i in Invoice, where: i.status == :succeeded and i.id == ^invoice_id, select: i.id)
        end
        |> Repo.update_all(set: assignments)

      case update_res do
        {1, [invoice_id]} ->
          case from(e in Event,
                 join: i in assoc(e, :invoice),
                 where: i.id == ^invoice_id,
                 select: e,
                 preload: [
                   :actor,
                   :commission,
                   invoice: [],
                   attachments: [:upload, :thumbnail, :preview]
                 ]
               )
               |> Repo.one() do
            %Event{} = ev -> {:ok, ev}
            nil -> {:error, :event_not_found}
          end

        {0, _} ->
          {:error, :invoice_not_found}
      end
    end)
    |> Ecto.Multi.run(:invoice, fn _, %{event: event} ->
      if event.invoice.refund_status == :succeeded do
        actor =
          if event.invoice.refunded_by_id do
            %User{id: event.invoice.refunded_by_id} |> Repo.reload!()
          else
            msg =
              "Bad State: invoice refund succeeded but refunded_by_id is nil! #{inspect(event.invoice)}"

            Logger.error(msg)
            raise msg
          end

        Commissions.create_event(
          :refund_processed,
          actor,
          event.commission,
          true,
          [],
          %{
            amount: Money.new(refund.amount, String.to_atom(String.upcase(refund.currency)))
          }
        )
      else
        Notifications.invoice_refund_updated(event.commission, event, actor)
      end

      Commissions.Notifications.commission_event_updated(event.commission, event, actor)
      {:ok, event.invoice}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{invoice: invoice}} ->
        {:ok, invoice}

      {:error, _, error, _} ->
        Logger.error("Failed to update invoice status to refunded: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Refunds or pays out invoices that have been held for longer than they should have.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def purge_expired_invoice(%Invoice{} = invoice) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:invoice, fn _, _ ->
      {:ok, invoice |> Repo.reload() |> Repo.preload(commission: [:studio])}
    end)
    |> Ecto.Multi.run(:final_invoice, fn _, %{invoice: invoice} ->
      system = Accounts.system_user()

      invoice_expired? =
        if is_nil(invoice.paid_on) do
          false
        else
          age = DateTime.utc_now() |> DateTime.diff(invoice.paid_on)

          age >= max_payment_age(invoice.commission.studio.country)
        end

      case {invoice_expired?, invoice.status} do
        {false, _} ->
          {:ok, invoice}

        {true, :succeeded} ->
          # If funds haven't been released, refund the client.
          with {:ok, invoice} <- refund_payment(system, invoice),
               :ok <- Notifications.expired_invoice_refunded(invoice) do
            {:ok, invoice}
          end

        {true, :released} ->
          # If they _have_ been released, pay out the studio if appropriate.
          payout =
            from(p in Payout,
              join: i in assoc(p, :invoices),
              where: i.id == ^invoice.id,
              order_by: [desc: p.updated_at]
            )
            |> Repo.one()

          case payout do
            %Payout{status: :paid} ->
              {:ok, invoice}

            %Payout{status: status, arrival_date: arrival_date}
            when status in [:pending, :in_transit] ->
              # There's a payout in flight, but we want to make sure that if
              # anything happens to it, we still correctly purge. So we
              # don't do anything, but we requeue purge_expired_invoice/1
              # for the day after the arrival_date
              # 1 day
              next = arrival_date |> DateTime.from_naive!("Etc/UTC") |> DateTime.add(60 * 60 * 24)

              with {:ok, _job} <- ExpiredInvoicePurger.schedule_purge(invoice, next) do
                {:ok, invoice}
              end

            _ ->
              # If there's no payout for this invoice or the payout is in a
              # failed state, initiate a new payout just for this invoice.
              with {:ok, _payout} <-
                     payout_invoice(system, %Studio{id: invoice.commission.studio_id}, invoice),
                   :ok <- Notifications.expired_invoice_paid_out(invoice) do
                {:ok, invoice}
              end
          end

        _ ->
          # Unpaid and refunded invoices don't really have a deadline.
          {:ok, invoice}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{final_invoice: invoice}} ->
        {:ok, invoice}

      {:error, _, error, _} ->
        Logger.error("Failed to purge expired invoice: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Maximum age, in seconds, that a payment can be before it needs to be either
  refunded or paid out, based on the studio country.

  See https://stripe.com/docs/connect/manual-payouts for more details.
  """
  def max_payment_age(country)
  # US studios can hold payments for 2 years.
  def max_payment_age(:US), do: 60 * 60 * 24 * 365 * 2
  # Thai studios can hold payments for only 10 days.
  def max_payment_age(:TH), do: 60 * 60 * 24 * 10
  # All others can hold them for 90 days.
  def max_payment_age(_), do: 60 * 60 * 24 * 90

  @doc """
  Warns clients and/or studio members that an invoice is overdue for
  processing and will either be refunded or paid out.
  """
  def warn_about_invoice_purge(%Invoice{} = _invoice) do
  end

  @doc """
  Cancels a pending payout.
  """
  def cancel_payout(%User{} = actor, %Studio{} = studio, payout_id) do
    with {:ok, _} <- Studios.check_studio_member(studio, actor) do
      case stripe_mod().cancel_payout(payout_id,
             headers: %{"Stripe-Account" => studio.stripe_id}
           ) do
        {:ok, %Stripe.Payout{id: ^payout_id, status: "canceled"}} ->
          # NOTE: db is updated on process_payout_updated, so we don't do it
          # here, particularly because we might not event have a payout entry in
          # our db at all (this function can get called when insertions fail).
          :ok

        {:error, %Stripe.Error{} = err} ->
          Logger.warn(
            "Failed to cancel payout #{payout_id} with code #{inspect(err.code)}: #{err.message}"
          )

          {:error, err}
      end
    end
  end

  @doc """
  Webhook handler for Stripe Payout state updates.
  """
  def process_payout_updated!(%Stripe.Payout{} = payout, id \\ nil) do
    query =
      cond do
        !is_nil(id) ->
          from(p in Payout, where: p.id == ^id, select: p)

        !is_nil(payout.id) ->
          from(p in Payout,
            where: p.stripe_payout_id == ^payout.id,
            select: p
          )

        true ->
          throw({:error, "Invalid process_payout_updated! call"})
      end

    case query
         |> Repo.update_all(
           set: [
             stripe_payout_id: payout.id,
             status: payout.status,
             failure_code: payout.failure_code,
             failure_message: payout.failure_message,
             arrival_date: payout.arrival_date |> DateTime.from_unix!() |> DateTime.to_naive(),
             method: payout.method,
             type: payout.type
           ]
         ) do
      {1, [payout]} ->
        Notifications.payout_updated(
          payout
          |> Repo.preload([:studio, :actor, [invoices: [:commission, :event]]])
        )

        {:ok, payout}

      {0, _} ->
        raise Ecto.NoResultsError, queryable: query
    end
  end

  ## Misc utilities

  defp stripe_mod do
    Application.get_env(:banchan, :stripe_mod)
  end
end
