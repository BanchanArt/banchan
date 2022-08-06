defmodule Banchan.Payments do
  @moduledoc """
  Context module for payments-related functionality: invoicing, payment
  processing, refunds, payouts, etc. Basically, everything Stripe-related.
  """

  import Ecto.Query, warn: false
  require Logger

  alias Banchan.Accounts.User
  alias Banchan.Commissions
  # TODO: Move payments-related notifications to Banchan.Payments.Notifications instead.
  alias Banchan.Commissions.{Commission, Event}
  alias Banchan.Payments.{Invoice, Notifications, Payout}
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Studios.Studio

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
  True if a given invoice has been paid. Expects an already-loaded invoice
  with the latest data.
  """
  def invoice_paid?(%Invoice{status: status}), do: status == :succeeded

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
  def invoice(actor, commission, current_user_member?, drafts, event_data)

  def invoice(actor, commission, false, drafts, event_data) do
    if :admin in actor.roles || :mod in actor.roles do
      invoice(actor, commission, true, drafts, event_data)
    else
      {:error, :unauthorized}
    end
  end

  def invoice(%User{} = actor, %Commission{} = commission, true, drafts, event_data) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = Repo.reload(actor)

        if Studios.is_user_in_studio?(actor, %Studio{id: commission.studio_id}) ||
             :admin in actor.roles ||
             :mod in actor.roles do
          with {:ok, event} <-
                 Commissions.create_event(:comment, actor, commission, true, drafts, event_data),
               %Invoice{} = invoice <- %Invoice{
                 client_id: commission.client_id,
                 commission: commission,
                 event: event
               },
               %Ecto.Changeset{} = changeset <- Invoice.creation_changeset(invoice, event_data),
               {:ok, invoice} <- Repo.insert(changeset) do
            send_event_update!(event.id, actor)
            {:ok, invoice}
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
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
  Pays out a Studio for the full available and released amount.
  """
  def payout_studio(%User{} = actor, %Studio{} = studio) do
    {:ok, balance} =
      stripe_mod().retrieve_balance(headers: %{"Stripe-Account" => studio.stripe_id})

    try do
      # TODO: notifications!
      {:ok,
       Enum.reduce(balance.available, [], fn avail, acc ->
         case payout_available!(actor, studio, avail) do
           {:ok, nil} ->
             acc

           {:ok, %Payout{} = payout} ->
             [payout | acc]
         end
       end)}
    catch
      %Stripe.Error{} = e ->
        Logger.error("Stripe error during payout: #{e.message}")
        {:error, e}

      {:error, err} ->
        Logger.error(%{message: "Internal error during payout", error: err})
        {:error, err}
    end
  end

  defp payout_available!(%User{} = actor, %Studio{} = studio, avail) do
    avail = Money.new(avail.amount, String.to_atom(String.upcase(avail.currency)))

    if avail.amount > 0 do
      {invoice_ids, invoice_count, total} = invoice_details(studio, avail)

      if total.amount > 0 do
        create_payout!(actor, studio, invoice_ids, invoice_count, total)
      else
        {:ok, nil}
      end
    else
      {:ok, nil}
    end
  end

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
          i.payout_available_on < ^now,
      order_by: {:asc, i.updated_at}
    )
    |> Repo.all()
    |> Enum.reduce_while({[], 0, Money.new(0, avail.currency)}, fn invoice,
                                                                   {invoice_ids, invoice_count,
                                                                    total} = acc ->
      invoice_total = invoice.total_transferred

      if invoice_total.amount + total.amount > avail.amount do
        {:halt, acc}
      else
        {:cont, {[invoice.id | invoice_ids], invoice_count + 1, Money.add(total, invoice_total)}}
      end
    end)
  end

  defp create_payout!(
         %User{} = actor,
         %Studio{} = studio,
         invoice_ids,
         invoice_count,
         %Money{} = total
       ) do
    {:ok, ret} =
      Repo.transaction(fn ->
        case %Payout{
               amount: total,
               studio_id: studio.id,
               actor_id: actor.id,
               invoices: from(i in Invoice, where: i.id in ^invoice_ids) |> Repo.all()
             }
             |> Repo.insert(returning: [:id]) do
          {:ok, payout} ->
            payout = payout |> Repo.preload(:invoices)
            actual_count = Enum.count(payout.invoices)

            if actual_count == invoice_count do
              {:ok, payout}
            else
              Logger.error(%{
                message:
                  "Wrong number of invoices associated with new Payout (expected: #{invoice_count}, actual: ${actual_count}"
              })

              throw({:error, "Payout failed due to an internal error."})
            end

          {:error, err} ->
            Logger.error(%{message: "Failed to insert payout row into database", error: err})
            throw({:error, "Payout failed due to an internal error."})
        end
      end)

    case ret do
      {:ok, payout} ->
        case create_stripe_payout(studio, total) do
          {:ok, stripe_payout} ->
            process_payout_updated!(stripe_payout, payout.id)

          {:error, err} ->
            Logger.error(%{message: "Failed to create Stripe payout", error: err})

            process_payout_updated!(
              %Stripe.Payout{
                status: :failed,
                arrival_date: DateTime.utc_now() |> DateTime.to_unix()
              },
              payout.id
            )

            throw(err)
        end

      {:error, err} ->
        {:error, err}
    end
  end

  defp create_stripe_payout(%Studio{} = studio, %Money{} = total) do
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
        {:error, error}
    end
  end

  ## Updating/Editing

  @doc """
  Releases a payment.
  """
  def release_payment(%User{} = actor, %Commission{} = commission, %Invoice{} = invoice) do
    {:ok, ret} =
      Repo.transaction(fn ->
        with {:ok, actor} <- Commissions.check_actor_edit_access(actor, commission),
             {1, _} <-
               from(i in Invoice,
                 join: c in assoc(i, :commission),
                 where:
                   i.id == ^invoice.id and c.client_id == ^actor.id and i.status == :succeeded
               )
               |> Repo.update_all(set: [status: :released]),
             %Event{} = ev <-
               from(e in Event,
                 where: e.id == ^invoice.event_id,
                 select: e,
                 preload: [:actor, invoice: [], attachments: [:upload, :thumbnail, :preview]]
               )
               |> Repo.one() do
          Commissions.Notifications.invoice_released(commission, ev, actor)
          Commissions.Notifications.commission_event_updated(commission, ev, actor)

          {:ok, ev}
        end
        |> case do
          {0, _} ->
            # Only succeeded invoices can be released.
            {:error, :invalid_invoice_status}

          {num, _} when is_integer(num) ->
            # NB(zkat): This would point to a bug.
            {:error, :updated_too_many_invoices}

          {:ok, val} ->
            {:ok, val}

          {:error, err} ->
            {:error, err}
        end
      end)

    ret
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
        name: "Commission Invoice Payment",
        quantity: 1,
        amount: amount.amount,
        currency: String.downcase(to_string(amount.currency))
      },
      %{
        name: "Extra Tip",
        quantity: 1,
        amount: tip.amount,
        currency: String.downcase(to_string(tip.currency))
      }
    ]

    with {stripe_id, platform_fee} <-
           from(studio in Studio,
             where: studio.id == ^commission.studio_id,
             select: {studio.stripe_id, studio.platform_fee}
           )
           |> Repo.one(),
         platform_fee <- Money.multiply(Money.add(amount, tip), platform_fee),
         transfer_amt <- amount |> Money.add(tip) |> Money.subtract(platform_fee),
         {:ok, session} <-
           stripe_mod().create_session(%{
             payment_method_types: ["card"],
             mode: "payment",
             cancel_url: uri,
             success_url: uri,
             line_items: items,
             payment_intent_data: %{
               transfer_data: %{
                 amount: transfer_amt.amount,
                 destination: stripe_id
               }
             }
           }),
         {:ok, _} <-
           invoice
           |> Invoice.submit_changeset(%{
             tip: tip,
             platform_fee: platform_fee,
             stripe_session_id: session.id,
             checkout_url: session.url,
             status: :submitted
           })
           |> Repo.update() do
      send_event_update!(event.id, actor)

      {:ok, session.url}
    end
  end

  @doc """
  Webhook handler for when a payment has been successfully processed by Stripe.
  """
  def process_payment_succeeded!(session) do
    {:ok, %{charges: %{data: [%{balance_transaction: txn_id, transfer: transfer}]}}} =
      stripe_mod().retrieve_payment_intent(session.payment_intent, %{}, [])

    {:ok, %{available_on: available_on, amount: amt, currency: curr}} =
      stripe_mod().retrieve_balance_transaction(txn_id, [])

    {:ok, transfer} = stripe_mod().retrieve_transfer(transfer)

    total_charged = Money.new(amt, String.to_atom(String.upcase(curr)))
    final_transfer_txn = transfer.destination_payment.balance_transaction

    total_transferred =
      Money.new(
        final_transfer_txn.amount,
        String.to_atom(String.upcase(final_transfer_txn.currency))
      )

    {:ok, available_on} = DateTime.from_unix(available_on)

    {:ok, _} =
      Repo.transaction(fn ->
        {1, [invoice]} =
          from(i in Invoice, where: i.stripe_session_id == ^session.id, select: i)
          |> Repo.update_all(
            set: [
              status: :succeeded,
              payout_available_on: available_on,
              total_charged: total_charged,
              total_transferred: total_transferred
            ]
          )

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
  def expire_payment(actor, invoice, current_user_member?)

  def expire_payment(%User{} = actor, invoice, false) do
    if :admin in actor.roles || :mod in actor.roles do
      expire_payment(actor, invoice, true)
    else
      {:error, :unauthorized}
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def expire_payment(
        %User{} = actor,
        %Invoice{} = invoice,
        true
      ) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()
        invoice = invoice |> Repo.reload() |> Repo.preload(:commission)

        if Studios.is_user_in_studio?(actor, %Studio{id: invoice.commission.studio_id}) ||
             :admin in actor.roles || :mod in actor.roles do
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
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Refunds a payment that hasn't been released yet.
  """
  def refund_payment(actor, invoice, current_user_member?)

  def refund_payment(actor, invoice, false) do
    if :admin in actor.roles || :mod in actor.roles do
      refund_payment(actor, invoice, true)
    else
      {:error, :unauthorized}
    end
  end

  def refund_payment(%User{} = actor, %Invoice{} = invoice, _) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.reload()
        invoice = invoice |> Repo.reload() |> Repo.preload(:commission)

        if Studios.is_user_in_studio?(actor, %Studio{id: invoice.commission.studio_id}) ||
             :admin in actor.roles || :mod in actor.roles do
          if invoice.status != :succeeded do
            Logger.error(%{
              message: "Attempted to refund an invoice that wasn't :succeeded.",
              invoice: invoice
            })

            {:error, :invoice_not_refundable}
          else
            process_refund_payment(actor, invoice)
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  defp process_refund_payment(%User{} = actor, %Invoice{} = invoice) do
    case refund_payment_on_stripe(invoice) do
      {:ok, %Stripe.Refund{status: "failed"} = refund} ->
        Logger.error(%{message: "Refund failed", refund: refund})
        process_refund_updated(refund, invoice.id, actor)

      {:ok, %Stripe.Refund{status: "canceled"} = refund} ->
        Logger.error(%{message: "Refund canceled", refund: refund})
        process_refund_updated(refund, invoice.id, actor)

      {:ok, %Stripe.Refund{status: "requires_action"} = refund} ->
        Logger.info(%{message: "Refund requires action", refund: refund})
        # This should eventually succeed asynchronously.
        process_refund_updated(refund, invoice.id, actor)

      {:ok, %Stripe.Refund{status: "succeeded"} = refund} ->
        process_refund_updated(refund, invoice.id, actor)

      {:ok, %Stripe.Refund{status: "pending"} = refund} ->
        process_refund_updated(refund, invoice.id, actor)

      {:error, %Stripe.Error{} = err} ->
        {:error, err}
    end
  end

  defp refund_payment_on_stripe(%Invoice{} = invoice) do
    case stripe_mod().retrieve_session(invoice.stripe_session_id, []) do
      {:ok, session} ->
        case stripe_mod().retrieve_payment_intent(session.payment_intent, %{}, []) do
          {:ok, %Stripe.PaymentIntent{charges: %{data: [%{id: charge_id}]}}} ->
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
                Logger.error(%{message: "Refund failed.", error: err})
                {:error, err}
            end

          {:error, err} ->
            Logger.error(%{
              message: "Failed to retrieve payment intent while refunding.",
              error: err
            })

            {:error, err}
        end

      {:error, err} ->
        Logger.error(%{message: "Failed to retrieve session while refunding.", error: err})
        {:error, err}
    end
  end

  @doc """
  Webhook handler for when a Stripe refund has been updated.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def process_refund_updated(%Stripe.Refund{} = refund, invoice_id, actor \\ nil) do
    {:ok, ret} =
      Repo.transaction(fn ->
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
          if is_nil(actor) do
            assignments
          else
            assignments ++ [refunded_by_id: actor.id]
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

    case ret do
      {:ok, event} ->
        if event.invoice.refund_status == :succeeded do
          actor =
            cond do
              is_nil(actor) && event.invoice.refunded_by_id ->
                %User{id: event.invoice.refunded_by_id} |> Repo.reload!()

              !is_nil(actor) ->
                actor

              true ->
                raise "Bad state: an invoice was succeeded that didn't already have a refunded_by_id."
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

      {:error, err} ->
        Logger.error(%{message: "Failed to update invoice status to refunded", error: err})
        {:error, :internal_error}
    end
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
          Logger.warn(%{
            message: "Failed to cancel payout #{payout_id}: #{err.message}",
            code: err.code
          })

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
