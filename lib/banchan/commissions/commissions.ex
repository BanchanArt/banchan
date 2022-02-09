defmodule Banchan.Commissions do
  @moduledoc """
  The Commissions context.
  """

  import Ecto.Query, warn: false
  alias Banchan.Repo

  alias Banchan.Accounts.User
  alias Banchan.Commissions.{Commission, Event, EventAttachment, LineItem}
  alias Banchan.Offerings
  alias Banchan.Offerings.OfferingOption
  alias Banchan.Studios.Studio
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

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
          events: [:actor, attachments: [:upload, :thumbnail]],
          line_items: [:option],
          offering: [:options]
        ]
    )
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
                option: nil,
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
              {:error, err} -> {:error, err}
              {:ok, event} -> {:ok, {commission, [event]}}
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
              {:error, err} -> {:error, err}
              {:ok, event} -> {:ok, {commission, [event]}}
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
    %Event{
      type: type,
      commission: commission,
      actor: actor,
      attachments: attachments
    }
    |> Event.changeset(attrs)
    |> Repo.insert()
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
        tmp_dir = Path.join([System.tmp_dir!(), upload.key])
        tmp_file = Path.join([tmp_dir, name])
        File.mkdir_p!(tmp_dir)
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
        File.rm_rf!(tmp_dir)
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
end
