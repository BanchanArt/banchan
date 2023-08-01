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
  alias Banchan.Payments
  alias Banchan.Payments.{Forex, Invoice, Notifications, Payout}
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
  Gets the final invoice for a commission, if one exists.
  """
  def final_invoice(%Commission{} = commission) do
    from(i in Invoice,
      where:
        i.commission_id == ^commission.id and i.final == true and
          i.status in [:succeeded, :released, :pending, :submitted],
      order_by: [desc: i.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Returns a pending invoice, if any.
  """
  def open_invoice(%Commission{} = commission) do
    from(i in Invoice,
      where: i.commission_id == ^commission.id and i.status in [:pending, :submitted]
    )
    |> Repo.one()
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
          # Final invoices that didn't have a tip don't have Stripe
          # sessions or transfers associated with them.
          where:
            c.studio_id == ^studio.id and
              (i.status == :succeeded or i.status == :released) and
              not is_nil(i.total_transferred),
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

  @doc """
  Gets the minimum amount that can be released from a commission (essentially,
  the commission's minimum price).

  We do this because having many very small transactions would be catastrophic
  for the platform, as Stripe costs scale really poorly in that case.
  """
  def minimum_release_amount do
    {amt, curr} = Application.fetch_env!(:banchan, :minimum_release_amount)
    Money.new(amt, curr)
  end

  @doc """
  Stripe's minimum transaction amount.
  """
  def minimum_transaction_amount do
    Money.new(50, :USD)
  end

  @doc """
  Returns the total amount of money that has been released for a commission.
  """
  def released_amount(%Commission{} = commission) do
    curr = Commissions.commission_currency(commission)

    from(i in Invoice,
      where: i.commission_id == ^commission.id and i.status == :released,
      select: i
    )
    |> Repo.all()
    |> Enum.reduce(Money.new(0, curr), fn invoice, total ->
      Money.add(invoice.amount, invoice.tip || Money.new(0, curr))
      |> Money.add(total)
    end)
  end

  @doc """
  Returns the total amount of money that is currently in escrow for a commission.
  """
  def escrowed_amount(%Commission{} = commission) do
    curr = Commissions.commission_currency(commission)

    from(i in Invoice,
      where: i.commission_id == ^commission.id and i.status == :succeeded,
      select: i
    )
    |> Repo.all()
    |> Enum.reduce(Money.new(0, curr), fn invoice, total ->
      Money.add(invoice.amount, invoice.tip || Money.new(0, curr))
      |> Money.add(total)
    end)
  end

  ## Creation

  @doc """
  Creates a new invoice.
  """
  def invoice(%User{} = actor, %Commission{} = commission, drafts, event_data, final? \\ false) do
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
    |> Ecto.Multi.run(:existing_open?, fn _repo, _ ->
      if open_invoice(commission) do
        {:error, :existing_open_invoice}
      else
        {:ok, true}
      end
    end)
    |> Ecto.Multi.run(:active_comm?, fn _repo, _ ->
      if Commissions.commission_active?(commission) do
        {:ok, true}
      else
        {:error, :inactive_commission}
      end
    end)
    |> Ecto.Multi.run(:event, fn _repo, %{checked_actor: actor} ->
      Commissions.create_event(:comment, actor, commission, true, drafts, event_data)
    end)
    |> Ecto.Multi.insert(:invoice, fn %{event: event} ->
      estimate = Commissions.line_item_estimate(Repo.preload(commission, :line_items).line_items)

      deposited = Commissions.deposited_amount(actor, commission, true)

      remaining = Money.subtract(estimate, deposited)

      %Invoice{
        client_id: commission.client_id,
        commission: commission,
        event: event,
        final: final?
      }
      |> Invoice.creation_changeset(
        event_data
        |> Map.put(
          "line_items",
          Enum.map(
            Repo.preload(commission, :line_items).line_items,
            &%{
              "name" => &1.name,
              "description" => &1.description,
              "amount" => %{
                "amount" => &1.amount.amount,
                "currency" => &1.amount.currency
              },
              "multiple" => &1.multiple,
              "count" => &1.count
            }
          )
        )
        |> Map.put("deposited", deposited)
        |> Map.put("required", "true"),
        remaining
      )
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
      |> case do
        {:ok, payouts} ->
          {:ok, Enum.reverse(payouts)}

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
          not is_nil(i.stripe_charge_id) and
          (is_nil(p.id) or p.status not in [:pending, :in_transit, :paid]) and
          fragment("(?).currency = ?::char(3)", i.total_transferred, ^currency_str) and
          (is_nil(i.payout_available_on) or i.payout_available_on <= ^now),
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

            Money.add(invoice_total, total) |> Money.cmp(avail) == :gt ->
              # NB(@zkat): This should _generally_ not happen, but may as well
              # check for it.
              Logger.error(
                "Invoice #{invoice.id} has a total of at least #{Money.add(invoice_total, total) |> Payments.print_money()}, but the available balance is only #{Payments.print_money(avail)}"
              )

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
          actor_id: actor.id,
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
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def release_payment(%User{} = actor, %Commission{} = commission, %Invoice{} = invoice) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:actor, fn _, _ ->
      Commissions.check_actor_edit_access(actor, commission)
    end)
    |> Ecto.Multi.run(:check_minimum_amount, fn _, _ ->
      min = minimum_release_amount()

      curr = Commissions.commission_currency(commission)

      released_amt =
        list_invoices(commission: commission, with_statuses: [:released])
        |> Enum.reduce(Money.new(0, curr), fn invoice, total ->
          Money.add(invoice.amount, invoice.tip || Money.new(0, curr))
          |> Money.add(total)
        end)

      total =
        Money.add(invoice.amount, invoice.tip || Money.new(0, curr))
        |> Money.add(released_amt)

      case cmp_money(min, total) do
        cmp when cmp in [:lt, :eq] ->
          {:ok, true}

        :gt ->
          {:error, :release_under_threshold}
      end
    end)
    |> Ecto.Multi.update_all(
      :invoices,
      fn %{actor: actor} ->
        from(i in Invoice,
          join: c in assoc(i, :commission),
          where:
            i.id == ^invoice.id and c.client_id == ^actor.id and i.status == :succeeded and
              c.id == ^commission.id,
          select: i
        )
      end,
      set: [status: :released]
    )
    |> Ecto.Multi.run(:updated_invoice, fn _, %{invoices: invoice_info} ->
      case invoice_info do
        {0, _} ->
          {:error, :invalid_invoice_status}

        {1, [invoice]} ->
          {:ok, invoice}

        {n, _} when is_integer(n) ->
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
    |> Ecto.Multi.run(:create_event, fn _, %{updated_invoice: invoice} ->
      Commissions.create_event(:invoice_released, actor, commission, false, [], %{
        amount: invoice.total_charged
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{event: event, actor: actor}} ->
        Commissions.Notifications.commission_event_updated(commission, event, actor)
        {:ok, event}

      {:error, _, error, _} ->
        {:error, error}
    end
  end

  @doc """
  Releases all completed payments for a commission.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def release_all_deposits(%User{} = actor, %Commission{} = commission) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:actor, fn _, _ ->
      Commissions.check_actor_edit_access(actor, commission)
    end)
    |> Ecto.Multi.run(:check_minimum_amount, fn _, _ ->
      min = minimum_release_amount()

      curr = Commissions.commission_currency(commission)

      total =
        list_invoices(commission: commission, with_statuses: [:released, :succeeded])
        |> Enum.reduce(Money.new(0, curr), fn invoice, total ->
          Money.add(invoice.amount, invoice.tip || Money.new(0, curr))
          |> Money.add(total)
        end)

      case cmp_money(min, total) do
        cmp when cmp in [:lt, :eq] ->
          {:ok, true}

        :gt ->
          {:error, :release_under_threshold}
      end
    end)
    |> Ecto.Multi.update_all(
      :invoices,
      fn %{actor: actor} ->
        from(i in Invoice,
          join: c in assoc(i, :commission),
          where: c.client_id == ^actor.id and i.status == :succeeded and c.id == ^commission.id,
          select: i
        )
      end,
      set: [status: :released]
    )
    |> Ecto.Multi.all(:events, fn _ ->
      from(e in Event,
        join: i in assoc(e, :invoice),
        where: e.commission_id == ^commission.id and i.commission_id == ^commission.id,
        select: e,
        preload: [:actor, invoice: [], attachments: [:upload, :thumbnail, :preview]]
      )
    end)
    |> Ecto.Multi.run(:create_event, fn _, %{invoices: {n, invoices}} ->
      if n > 0 do
        Commissions.create_event(:all_invoices_released, actor, commission, false, [], %{
          amount: invoices |> Enum.map(& &1.amount) |> Enum.reduce(&Money.add/2)
        })
      end

      {:ok, true}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{events: events, actor: actor, invoices: {n, invoices}}} ->
        if n > 0 do
          Enum.each(events, fn event ->
            Commissions.Notifications.commission_event_updated(commission, event, actor)
          end)
        end

        {:ok, invoices}

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
        %Event{invoice: %Invoice{amount: %Money{amount: 0}, tip: tip, final: true} = invoice} =
          event,
        %Commission{} = commission,
        _uri,
        %Money{amount: 0}
      )
      when is_nil(tip) or tip.amount == 0 do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_invoice, fn _ ->
      invoice
      |> Invoice.submit_changeset(%{
        tip: Money.new(0, invoice.amount.currency),
        platform_fee: Money.new(0, invoice.amount.currency),
        status: :succeeded
      })
    end)
    |> Ecto.Multi.run(:finalize, fn _, %{updated_invoice: invoice} ->
      client = Repo.reload!(%User{id: invoice.client_id})
      {:ok, _} = Commissions.update_status(client, commission, :approved)
      {:ok, _} = release_all_deposits(client, commission)

      if client.email do
        Notifications.send_receipt(
          invoice |> Repo.reload(),
          client,
          commission |> Repo.reload() |> Repo.preload(line_items: [])
        )
      end

      send_event_update!(event.id, actor)
      {:ok, true}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, :no_payment_necessary}

      {:error, _, error, _} ->
        Logger.error("Failed to process payment: #{inspect(error)}")
        {:error, :payment_failed}
    end
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
            name:
              if invoice.final do
                "Final Invoice Payment"
              else
                "Commission Deposit"
              end,
            description:
              if invoice.final do
                "Final payment for commission '#{commission.title}'. Will be immediately released on payment."
              else
                "Deposit for commission '#{commission.title}'. Will be kept in escrow until commission is completed or invoice is released early."
              end,
            # Digital Finished Artwork - downloaded - non subscription - with
            # permanent rights
            tax_code: "txcd_10505001"
          },
          unit_amount: amount.amount,
          currency: String.downcase(to_string(amount.currency)),
          tax_behavior: "exclusive"
        },
        quantity: 1
      }
    ]

    items =
      if tip.amount > 0 do
        items ++
          [
            %{
              price_data: %{
                product_data: %{
                  name: "Extra Tip",
                  description: "Thank you for your generosity!",
                  # Optional Gratuity
                  tax_code: "txcd_90020001"
                },
                unit_amount: tip.amount,
                currency: String.downcase(to_string(tip.currency)),
                tax_behavior: "exclusive"
              },
              quantity: 1
            }
          ]
      else
        items
      end

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

        if invoice.final do
          {:ok, _} = Commissions.update_status(client, commission, :approved)
          {:ok, _} = release_all_deposits(client, commission)
        end

        if client.email do
          Notifications.send_receipt(
            invoice |> Repo.reload(),
            client,
            commission |> Repo.reload() |> Repo.preload(line_items: [])
          )
        end

        send_event_update!(invoice.event_id)
      end)

    :ok
  end

  @doc """
  Go over all payments for a commission, cancel any pending ones, and refund
  any unreleased completed ones.
  """
  def refund_and_cancel_all_payments(%User{} = actor, %Commission{} = commission) do
    with {:ok, _} <- Commissions.check_actor_edit_access(actor, commission) do
      # We intentionally do this outside of a transaction, in case a single one
      # fails, so we don't end up in a weird state on random errors.
      list_invoices(commission: commission, with_statuses: [:pending, :submitted, :succeeded])
      |> Enum.reduce_while(:ok, fn invoice, :ok ->
        case invoice.status do
          status when status in [:pending, :submitted] ->
            case expire_payment(actor, invoice) do
              {:ok, _} -> {:cont, :ok}
              {:error, error} -> {:halt, {:error, error}}
            end

          :succeeded ->
            case refund_payment(actor, invoice) do
              {:ok, _} -> {:cont, :ok}
              {:error, error} -> {:halt, {:error, error}}
            end

          _ ->
            :ok
        end
      end)
    end
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
             refund_application_fee: false
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
          Logger.warning(
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

  ## Exchange Rates

  @doc """
  Returns the atom for the configured platform currency.
  """
  def platform_currency, do: Application.fetch_env!(:banchan, :platform_currency)

  @doc """
  Compares two Money structs, converting the second to the first's currency
  according to the latest exchange rates.

  Returns `:lt` if the first item is less than the second, `:gt` if the first
  item is greater than the second, and `:eq` if they're the same.
  """
  def cmp_money(%Money{} = a, %Money{} = b) do
    # Ideally, `a` here will usually be in :platform_currency, to minimize
    # exchange rate lookups.
    b = if a.currency == b.currency, do: b, else: convert_money(b, a.currency)
    Money.cmp(a, b)
  end

  @doc """
  Converts a Money struct to a different currency, according to the latest exchange rates.
  """
  def convert_money(%Money{currency: from} = money, to) when is_atom(to) do
    if money.currency == to do
      money
    else
      rate = get_exchange_rate(to, from)

      if is_nil(rate) do
        raise "No exchange rate available for #{from} -> #{to}"
      else
        Money.parse!(
          Decimal.div(
            Money.to_decimal(money),
            Decimal.from_float(rate)
          )
          |> Decimal.to_string(),
          to
        )
      end
    end
  end

  @doc """
  Fetches the latest exchange rate for the given currencies. Returns `nil` if
  no such exchange rate is availale.
  """
  def get_exchange_rate(from, to) when is_atom(from) and is_atom(to) do
    Forex.get_forex_rate(Forex, from, to)
  end

  @doc """
  Fetches the latest exchange rates from an API and updates the values in the
  database, returning the latest values as a Map.
  """
  def update_exchange_rates(base_currency) when is_atom(base_currency) do
    # This is a nice, free API and we don't really hit it very often at all.
    case http_mod().get("https://api.exchangerate.host/latest?base=#{base_currency}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        currency_names = Studios.Common.supported_currencies() |> Enum.map(&to_string/1)

        Repo.transaction(fn ->
          body
          |> Jason.decode!()
          |> Map.get("rates")
          |> Enum.filter(fn {currency, _} ->
            currency in currency_names
          end)
          |> Map.new(fn {currency, rate} ->
            {String.to_existing_atom(currency),
             Repo.insert!(
               Forex.changeset(%Forex{from: base_currency}, %{to: currency, rate: rate}),
               returning: true,
               on_conflict: {:replace_all_except, [:id, :inserted_at]},
               conflict_target: [:from, :to]
             )}
          end)
        end)

      {:error, error} ->
        Logger.error("Failed to update exchange rates for #{base_currency}: #{inspect(error)}")
        {:error, error}
    end
  end

  @doc """
  Loads the exchange rates for a currency from the database.
  """
  def load_exchange_rates(base_currency) when is_atom(base_currency) do
    from(x in Forex, where: x.from == ^base_currency, select: x)
    |> Repo.all()
    |> Map.new(fn forex ->
      {forex.to, forex}
    end)
  end

  @doc """
  Clears saved exchange rates for a currency both from the database and the
  in-memory cache.
  """
  def clear_exchange_rates(base_currency) when is_atom(base_currency) do
    from(x in Forex, where: x.from == ^base_currency, select: x)
    |> Repo.delete_all()

    Forex.forget_rates(Forex, base_currency)
  end

  ## Misc utilities

  @doc """
  Formats money with improved semantics over the default Money.to_string/2.
  For example, differentiating between different kinds of dollars that would
  usually just use `$` as a symbol.
  """
  def print_money(%Money{} = money, symbol \\ true) do
    if symbol do
      case Money.Currency.symbol(money) do
        "$" -> currency_symbol(money.currency) <> Money.to_string(money, symbol: false)
        "" -> currency_symbol(money.currency) <> " " <> Money.to_string(money, symbol: false)
        " " -> currency_symbol(money.currency) <> " " <> Money.to_string(money, symbol: false)
        _ -> Money.to_string(money, symbol: true)
      end
    else
      Money.to_string(money, symbol: false)
    end
  end

  def currency_symbol(%Money{currency: currency}) do
    currency_symbol(currency)
  end

  def currency_symbol(currency) when is_atom(currency) do
    case Money.Currency.symbol(currency) do
      "$" -> dollar_prefix(currency) <> "$"
      "" -> blank_prefix(currency)
      " " -> blank_prefix(currency)
      other -> other
    end
  end

  defp dollar_prefix(:USD), do: ""
  defp dollar_prefix(:AUD), do: "AU"
  defp dollar_prefix(:ARS), do: "Arg"
  defp dollar_prefix(:BBD), do: "BB"
  defp dollar_prefix(:BMD), do: "BD"
  defp dollar_prefix(:BND), do: "B"
  defp dollar_prefix(:BSD), do: "B"
  defp dollar_prefix(:CVE), do: "Esc"
  defp dollar_prefix(:KYD), do: "KY"
  defp dollar_prefix(:CLP), do: "CLP"
  defp dollar_prefix(:COP), do: "COP"
  defp dollar_prefix(:XCD), do: "EC"
  defp dollar_prefix(:FJD), do: "FJ"
  defp dollar_prefix(:GYD), do: "GY"
  defp dollar_prefix(:HKD), do: "HK"
  defp dollar_prefix(:LRD), do: "LD"
  defp dollar_prefix(:MXN), do: "Mex"
  defp dollar_prefix(:NZD), do: "NZ"
  defp dollar_prefix(:NAD), do: "N"
  defp dollar_prefix(:SBD), do: "SI"
  defp dollar_prefix(:SRD), do: "Sr"
  defp dollar_prefix(_), do: ""

  defp blank_prefix(:XOF), do: "F.CFA"
  defp blank_prefix(:XPF), do: "F.CFP"
  defp blank_prefix(:HTG), do: "G"
  defp blank_prefix(:LSL), do: "R"
  defp blank_prefix(:RWF), do: "R₣‎"
  defp blank_prefix(:TJS), do: "SM"
  defp blank_prefix(_), do: ""

  defp stripe_mod do
    Application.get_env(:banchan, :stripe_mod)
  end

  defp http_mod do
    Application.get_env(:banchan, :http_mod)
  end
end
