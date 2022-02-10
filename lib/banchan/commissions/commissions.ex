defmodule Banchan.Commissions do
  @moduledoc """
  The Commissions context.
  """

  import Ecto.Query, warn: false
  alias Banchan.Repo

  alias Banchan.Accounts.User
  alias Banchan.Commissions.{Commission, Event, EventAttachment, Invoice, LineItem}
  alias Banchan.Offerings
  alias Banchan.Offerings.OfferingOption
  alias Banchan.Studios.Studio
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  @pubsub Banchan.PubSub

  def list_commission_data_for_dashboard(%User{} = user, page, order \\ nil) do
    main_dashboard_query(user)
    |> dashboard_query_order_by(order)
    |> Repo.paginate(page: page, page_size: 10)
  end

  defp main_dashboard_query(%User{} = user) do
    from s in Studio,
      join: client in User,
      join: c in Commission,
      join: e in Event,
      where:
        c.id == e.commission_id and
          c.studio_id == s.id and
          c.client_id == client.id and
          (c.client_id == ^user.id or
             ^user.id in subquery(studio_artists_query())),
      group_by: [c.id, s.id, client.id, client.handle, s.handle, s.name],
      select: %{
        commission: %Commission{
          id: c.id,
          title: c.title,
          status: c.status,
          public_id: c.public_id,
          inserted_at: c.inserted_at
        },
        client: %User{
          id: client.id,
          name: client.name,
          handle: client.handle,
          pfp_thumb_id: client.pfp_thumb_id
        },
        studio: %Studio{
          id: s.id,
          handle: s.handle,
          name: s.name
        },
        updated_at: max(e.inserted_at)
      }
  end

  defp studio_artists_query do
    from s in Studio,
      join: u in User,
      join: us in "users_studios",
      join: c in Commission,
      where: u.id == us.user_id and s.id == us.studio_id and c.studio_id == s.id,
      select: u.id
  end

  defp dashboard_query_order_by(query, order) do
    case order do
      {ord, :client_handle} ->
        query |> order_by([c, client], [{^ord, client.handle}])

      {ord, :studio_handle} ->
        query |> order_by([c, client, s], [{^ord, s.handle}])

      {ord, field} ->
        query |> order_by([{^ord, ^field}])

      nil ->
        query
    end
  end

  @doc """
  Gets a single commission for a studio.

  Raises `Ecto.NoResultsError` if the Commission does not exist.

  ## Examples

      iex> get_commission!(studio, "lkajweirj0")
      %Commission{}

      iex> get_commission!(studio, "oiwejoa13d")
      ** (Ecto.NoResultsError)

  """
  def get_commission!(studio, public_id, current_user, current_user_member?) do
    Repo.one!(
      from c in Commission,
        where:
          c.studio_id == ^studio.id and c.public_id == ^public_id and
            (^current_user_member? or c.client_id == ^current_user.id),
        preload: [
          client: [],
          studio: [],
          events: [:actor, invoice: [], attachments: [:upload, :thumbnail]],
          line_items: [:option],
          offering: [:options]
        ]
    )
  end

  def subscribe_to_commission_events(%Commission{public_id: public_id}) do
    Phoenix.PubSub.subscribe(@pubsub, "commission:#{public_id}")
  end

  @doc """
  Creates a commission.

  ## Examples

      iex> create_commission(actor, studio, offering, %{field: value})
      {:ok, %Commission{}}

      iex> create_commission(actor, studio, offering, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_commission(actor, studio, offering, line_items, attachments, attrs \\ %{}) do
    {:ok, ret} =
      Repo.transaction(fn ->
        available_slot_count = Offerings.offering_available_slots(offering)
        available_proposal_count = Offerings.offering_available_proposals(offering)

        maybe_close_offering(offering, available_slot_count, available_proposal_count)

        cond do
          !is_nil(available_slot_count) && available_slot_count <= 0 ->
            {:error, :no_slots_available}

          !is_nil(available_proposal_count) && available_proposal_count <= 0 ->
            {:error, :no_proposals_available}

          true ->
            insert_commission(actor, studio, offering, line_items, attachments, attrs)
        end
      end)

    ret
  end

  defp maybe_close_offering(offering, available_slot_count, available_proposal_count) do
    # Make sure we close the offering if we're out of slots or proposals.
    close_slots = !is_nil(available_slot_count) && available_slot_count <= 1
    close_proposals = !is_nil(available_proposal_count) && available_proposal_count <= 1
    close = close_slots || close_proposals

    if close do
      {:ok, _} = Offerings.update_offering(offering, %{open: false})
    end
  end

  defp insert_commission(actor, studio, offering, line_items, attachments, attrs) do
    %Commission{
      studio: studio,
      offering: offering,
      client: actor,
      line_items: line_items,
      events: [
        %{
          actor: actor,
          type: :comment,
          text: Map.get(attrs, "description", ""),
          attachments: attachments
        }
      ]
    }
    |> Commission.changeset(attrs)
    |> Repo.insert()
  end

  def update_status(%User{} = actor, %Commission{} = commission, status) do
    {:ok, ret} =
      Repo.transaction(fn ->
        {:ok, commission} =
          commission
          |> Commission.changeset(%{status: status})
          |> Repo.update()

        {:ok, event} = create_event(:status, actor, commission, [], %{status: status})

        Phoenix.PubSub.broadcast!(
          @pubsub,
          "commission:#{commission.public_id}",
          %Phoenix.Socket.Broadcast{
            topic: "commission:#{commission.public_id}",
            event: "new_status",
            payload: commission.status
          }
        )

        {:ok, {commission, [event]}}
      end)

    ret
  end

  def add_line_item(%User{} = actor, %Commission{} = commission, option) do
    {:ok, ret} =
      Repo.transaction(fn ->
        line_item =
          case option do
            %OfferingOption{} ->
              %LineItem{
                option: option,
                amount: option.price || Money.new(0, :USD),
                name: option.name,
                description: option.description
              }

            %{amount: amount, name: name, description: description} ->
              %LineItem{
                amount: amount,
                name: name,
                description: description
              }
          end

        case commission
             |> Commission.changeset(%{
               tos_ok: true
             })
             |> Ecto.Changeset.put_assoc(:line_items, commission.line_items ++ [line_item])
             |> Repo.update() do
          {:error, err} ->
            {:error, err}

          {:ok, commission} ->
            # credo:disable-for-next-line Credo.Check.Refactor.Nesting
            case create_event(:line_item_added, actor, commission, [], %{
                   amount: line_item.amount,
                   text: line_item.name
                 }) do
              {:error, err} ->
                {:error, err}

              {:ok, event} ->
                Phoenix.PubSub.broadcast_from!(
                  @pubsub,
                  self(),
                  "commission:#{commission.public_id}",
                  %Phoenix.Socket.Broadcast{
                    topic: "commission:#{commission.public_id}",
                    event: "line_items_changed",
                    payload: commission.line_items
                  }
                )

                {:ok, {commission |> Repo.preload(line_items: [:option]), [event]}}
            end
        end
      end)

    ret
  end

  def remove_line_item(%User{} = actor, %Commission{} = commission, line_item) do
    {:ok, ret} =
      Repo.transaction(fn ->
        line_items = Enum.filter(commission.line_items, &(&1.id != line_item.id))

        case commission
             |> Commission.changeset(%{
               tos_ok: true
             })
             |> Ecto.Changeset.put_assoc(:line_items, line_items)
             |> Repo.update() do
          {:error, err} ->
            {:error, err}

          {:ok, commission} ->
            # credo:disable-for-next-line Credo.Check.Refactor.Nesting
            case create_event(:line_item_removed, actor, commission, [], %{
                   amount: line_item.amount,
                   text: line_item.name
                 }) do
              {:error, err} ->
                {:error, err}

              {:ok, event} ->
                Phoenix.PubSub.broadcast_from!(
                  @pubsub,
                  self(),
                  "commission:#{commission.public_id}",
                  %Phoenix.Socket.Broadcast{
                    topic: "commission:#{commission.public_id}",
                    event: "line_items_changed",
                    payload: commission.line_items
                  }
                )

                {:ok, {commission, [event]}}
            end
        end
      end)

    ret
  end

  @doc """
  Deletes a commission.

  ## Examples

      iex> delete_commission(commission)
      {:ok, %Commission{}}

      iex> delete_commission(commission)
      {:error, %Ecto.Changeset{}}

  """
  def delete_commission(%Commission{} = commission) do
    Repo.delete(commission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking commission changes.

  ## Examples

      iex> change_commission(commission)
      %Ecto.Changeset{data: %Commission{}}

  """
  def change_commission(%Commission{} = commission, attrs \\ %{}) do
    Commission.changeset(commission, attrs)
  end

  @doc """
  Returns the list of commission_events.

  ## Examples

      iex> list_commission_events()
      [%Event{}, ...]

  """
  def list_commission_events(commission) do
    Repo.all(from e in Event, where: e.commission_id == ^commission.id)
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.

  ## Examples

      iex> get_event!(123)
      %Event{}

      iex> get_event!(456)
      ** (Ecto.NoResultsError)

  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates a event.

  ## Examples

      iex> create_event(actor, commission, %{field: value})
      {:ok, %Event{}}

      iex> create_event(actor, commission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_event(type, %User{} = actor, %Commission{} = commission, attachments, attrs \\ %{})
      when is_atom(type) do
    ret =
      %Event{
        type: type,
        commission: commission,
        actor: actor,
        attachments: attachments
      }
      |> Event.changeset(attrs)
      |> Repo.insert()

    case ret do
      {:ok, event} ->
        Phoenix.PubSub.broadcast!(
          @pubsub,
          "commission:#{commission.public_id}",
          %Phoenix.Socket.Broadcast{
            topic: "commission:#{commission.public_id}",
            event: "new_events",
            payload: [%{event | invoice: nil}]
          }
        )

      _ ->
        nil
    end

    ret
  end

  @doc """
  Updates a event.

  ## Examples

      iex> update_event(event, %{field: new_value})
      {:ok, %Event{}}

      iex> update_event(event, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a event.

  ## Examples

      iex> delete_event(event)
      {:ok, %Event{}}

      iex> delete_event(event)
      {:error, %Ecto.Changeset{}}

  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.

  ## Examples

      iex> change_event(event)
      %Ecto.Changeset{data: %Event{}}

  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  def change_event_text(%Event{} = event, attrs \\ %{}) do
    Event.text_changeset(event, attrs)
  end

  def send_event_update!(event_id) do
    event =
      from(e in Event,
        where: e.id == ^event_id,
        select: e,
        preload: [:actor, invoice: [], attachments: [:upload, :thumbnail]]
      )
      |> Repo.one!()

    public_id =
      from(c in Commission, where: c.id == ^event.commission_id, select: c.public_id)
      |> Repo.one!()

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "commission:#{public_id}",
      %Phoenix.Socket.Broadcast{
        topic: "commission:#{public_id}",
        event: "event_updated",
        payload: event
      }
    )
  end

  # This one expects binaries for everything because it looks everything up in one fell swoop.
  def get_attachment_if_allowed!(studio, commission, key, user) do
    Repo.one!(
      from ea in EventAttachment,
        join: s in Studio,
        join: ul in Upload,
        join: e in Event,
        join: c in Commission,
        select: ea,
        where:
          s.handle == ^studio and
            c.public_id == ^commission and
            ul.key == ^key and
            ea.upload_id == ul.id and
            e.id == ea.event_id and
            e.commission_id == c.id and
            c.studio_id == s.id and
            (c.client_id == ^user.id or ^user.id in subquery(studio_artists_query())),
        preload: [:upload, :thumbnail]
    )
  end

  def make_attachment!(%User{} = user, src, type, name) do
    upload = Uploads.save_file!(user, src, type, name)

    thumbnail =
      if Uploads.image?(upload) || Uploads.video?(upload) do
        tmp_file = Path.join([System.tmp_dir!(), upload.key <> Path.extname(name)])
        File.mkdir_p!(Path.dirname(tmp_file))
        File.rename(src, tmp_file)

        mog =
          Mogrify.open(tmp_file)
          |> Mogrify.format("jpeg")
          |> Mogrify.gravity("Center")
          |> Mogrify.resize_to_fill("128x128")
          |> Mogrify.save()

        final_path =
          if Uploads.video?(upload) do
            mog.path |> String.replace(~r/\.jpeg$/, "-0.jpeg")
          else
            mog.path
          end

        thumb = Uploads.save_file!(user, final_path, "image/jpeg", "thumbnail.jpg")
        File.rm!(tmp_file)
        File.rm!(final_path)

        thumb
      end

    %EventAttachment{
      upload: upload,
      thumbnail: thumbnail
    }
  end

  def delete_attachment!(%EventAttachment{} = event_attachment) do
    # NOTE: This also deletes any associated uploads, because of the db ON DELETE
    Repo.delete!(event_attachment)
  end

  def invoice(%User{} = actor, %Commission{} = commission, amount) do
    {:ok, _} =
      Repo.transaction(fn ->
        {:ok, event} = create_event(:invoice, actor, commission, [], %{amount: amount})

        {:ok, _} =
          %Invoice{
            commission: commission,
            event: event
          }
          |> Invoice.amount_changeset(%{"amount" => amount})
          |> Repo.insert()

        send_event_update!(event.id)
      end)
  end

  def process_payment!(
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

    platform_fee = Money.multiply(Money.add(amount, tip), commission.studio.platform_fee)

    {:ok, session} =
      Stripe.Session.create(%{
        payment_method_types: ["card"],
        mode: "payment",
        cancel_url: uri,
        success_url: uri,
        line_items: items,
        payment_intent_data: %{
          application_fee_amount: platform_fee.amount,
          transfer_data: %{
            destination: commission.studio.stripe_id
          }
        }
      })

    invoice
    |> Invoice.submit_changeset(%{
      tip: tip,
      platform_fee: platform_fee,
      stripe_session_id: session.id,
      checkout_url: session.url,
      status: :submitted
    })
    |> Repo.update!()

    send_event_update!(event.id)

    session.url
  end

  def process_payment_succeeded!(session) do
    {:ok, %{charges: %{data: [%{balance_transaction: txn_id}]}}} =
      Stripe.PaymentIntent.retrieve(session.payment_intent, %{})

    {:ok, %{available_on: available_on}} = Stripe.BalanceTransaction.retrieve(txn_id)

    {:ok, available_on} = DateTime.from_unix(available_on)

    {1, [invoice]} =
      from(i in Invoice, where: i.stripe_session_id == ^session.id, select: i)
      |> Repo.update_all(
        set: [
          status: :succeeded,
          payout_available_on: available_on
        ]
      )

    send_event_update!(invoice.event_id)
    :ok
  end

  def process_payment_expired!(session) do
    {1, [invoice]} =
      from(i in Invoice, where: i.stripe_session_id == ^session.id, select: i)
      |> Repo.update_all(set: [status: :expired])

    send_event_update!(invoice.event_id)
  end

  def expire_payment!(%Invoice{id: id, stripe_session_id: nil}) do
    {1, [invoice]} =
      from(i in Invoice, where: i.id == ^id, select: i)
      |> Repo.update_all(set: [status: :expired])

    send_event_update!(invoice.event_id)
  end

  def expire_payment!(%Invoice{stripe_session_id: session_id}) do
    {:ok, _} =
      Stripe.Request.new_request([])
      |> Stripe.Request.put_endpoint("checkout/sessions/#{session_id}/expire")
      |> Stripe.Request.put_method(:post)
      |> Stripe.Request.make_request()

    # NOTE: We don't manually expire the invoice in the database here. That's
    # handled by process_payment_expired!/1 when the webhook fired.
    :ok
  end
end
