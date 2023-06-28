defmodule Banchan.Commissions do
  @moduledoc """
  The Commissions context.
  """

  import Ecto.Query, warn: false

  alias Banchan.Accounts
  alias Banchan.Accounts.User

  alias Banchan.Commissions.{
    CommentHistory,
    Commission,
    CommissionArchived,
    CommissionFilter,
    Common,
    Event,
    EventAttachment,
    Invoice,
    LineItem,
    Notifications
  }

  alias Banchan.Offerings
  alias Banchan.Offerings.{Offering, OfferingOption}
  alias Banchan.Payments.Invoice
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload
  alias Banchan.Workers.{Thumbnailer, UploadDeleter}

  ## Events

  @pubsub Banchan.PubSub

  @doc """
  Subscribes to all new commission broadcasts.
  """
  def subscribe_to_new_commissions do
    Phoenix.PubSub.subscribe(@pubsub, "commission")
  end

  @doc """
  Unsubscribes from all new commission broadcasts.
  """
  def unsubscribe_from_new_commissions do
    Phoenix.PubSub.unsubscribe(@pubsub, "commission")
  end

  @doc """
  Subscribes to new commission events and event updates.
  """
  def subscribe_to_commission_events(%Commission{public_id: public_id}) do
    Phoenix.PubSub.subscribe(@pubsub, "commission:#{public_id}")
  end

  @doc """
  Unsubscribes from new commission events and event updates.
  """
  def unsubscribe_from_commission_events(%Commission{public_id: public_id}) do
    Phoenix.PubSub.unsubscribe(@pubsub, "commission:#{public_id}")
  end

  ## Getting/Listing

  @doc """
  Über query for the `My Commissions` page. This is a paginated query that
  accepts a `CommissionFilter` and a variety of options.

  ## Filters

  The `CommissionFilter` fields have the following effects on this query:

    * `search` - Webquery-style search string that will match various
      Commission data, including comment text, title, etc.
    * `client` - Webquery-style search string to filter for specific clients.
    * `studio` - Webquery-style search string to filter for specific studios.
    * `statuses` - List of statuses to filter to. [] or nil will match all
      statuses.
    * `show_archived` - Whether to show archived commissions
    * `admin_show_all` - Admins-only: Whether to show all commissions,
      regardless of whether the current user is a participant.

  ## Options

    * `page` - The page number to return. Defaults to 1.
    * `page_size` - The number of items to return per page. Defaults to 24.
    * `order_by` - Sort order, and in some cases, filters. Defaults to
      `:recently_updated`. Supports the following values:
      * `:recently_updated` - List by most recently updated commissions (with
        the newest events first).
      * `:oldest_updated` - List by least recently updated commissions.
      * `:status` - Sorts by status order (in the order statuses are listed in
        the enum).
  """
  def list_commissions(
        %User{} = user,
        %CommissionFilter{} = filter,
        opts \\ []
      ) do
    main_dashboard_query(user)
    |> dashboard_query_filter(filter)
    |> dashboard_order_by(opts)
    |> Repo.paginate(
      page_size: Keyword.get(opts, :page_size, 24),
      page: Keyword.get(opts, :page, 1)
    )
  end

  defp main_dashboard_query(%User{} = user) do
    from c in Commission,
      as: :commission,
      left_join: s in assoc(c, :studio),
      as: :studio,
      left_join: artist in assoc(s, :artists),
      as: :artist,
      join: u in User,
      as: :current_user,
      on: u.id == ^user.id,
      left_join: a in CommissionArchived,
      on: a.commission_id == c.id and a.user_id == u.id,
      as: :archived,
      left_join: client in assoc(c, :client),
      on: is_nil(client.deactivated_at),
      as: :client,
      join: e in assoc(c, :events),
      as: :events,
      group_by: [c.id, s.id, client.id, client.handle, s.handle, s.name, a.archived],
      # order_by: {:desc, max(e.inserted_at)},
      select: %{
        commission: c,
        client: client,
        studio: s,
        archived: coalesce(a.archived, false),
        updated_at: max(e.inserted_at)
      }
  end

  defmacro status_order(arg) do
    cases =
      Common.status_values()
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {status, idx} ->
        # NB(zkat): I'm sorry for not using fragment(). I don't think I can.
        "WHEN '#{status}' THEN #{idx}"
      end)

    quote do
      fragment(unquote("CASE ? #{cases} ELSE NULL END"), unquote(arg))
    end
  end

  defp dashboard_order_by(q, opts) do
    case Keyword.fetch(opts, :order_by) do
      {:ok, :recently_updated} ->
        q
        |> order_by([events: e], {:desc, max(e.inserted_at)})

      {:ok, :oldest_updated} ->
        q
        |> order_by([events: e], {:asc, max(e.inserted_at)})

      {:ok, :status} ->
        q
        |> order_by([commission: comm], {:asc, status_order(comm.status)})

      :error ->
        q
        |> order_by([events: e], {:desc, max(e.inserted_at)})
    end
  end

  defp dashboard_query_filter(query, %CommissionFilter{} = filter) do
    query
    |> filter_search(filter)
    |> filter_client(filter)
    |> filter_studio(filter)
    |> filter_statuses(filter)
    |> filter_show_archived(filter)
    |> filter_admin_show_all(filter)
  end

  defp filter_search(query, %CommissionFilter{} = filter) do
    if is_nil(filter.search) || filter.search == "" do
      query
    else
      query
      |> where(
        [commission: c, events: e],
        fragment("? @@ websearch_to_tsquery('banchan_fts', ?)", c.search_vector, ^filter.search) or
          fragment("? @@ websearch_to_tsquery('banchan_fts', ?)", e.search_vector, ^filter.search)
      )
    end
  end

  defp filter_client(query, %CommissionFilter{} = filter) do
    if is_nil(filter.client) || filter.client == "" do
      query
    else
      query
      |> where(
        [client: client],
        fragment(
          "? @@ websearch_to_tsquery('banchan_fts', ?)",
          client.search_vector,
          ^filter.client
        )
      )
    end
  end

  defp filter_studio(query, %CommissionFilter{} = filter) do
    if is_nil(filter.studio) || filter.studio == "" do
      query
    else
      query
      |> where(
        [studio: s],
        fragment("? @@ websearch_to_tsquery('banchan_fts', ?)", s.search_vector, ^filter.studio)
      )
    end
  end

  defp filter_statuses(query, %CommissionFilter{} = filter) do
    if is_nil(filter.statuses) || Enum.empty?(filter.statuses) do
      query
    else
      query
      |> where([commission: c], c.status in ^filter.statuses)
    end
  end

  defp filter_show_archived(query, %CommissionFilter{} = filter) do
    if filter.show_archived do
      query
    else
      query
      |> where([archived: archived], not coalesce(archived.archived, false))
    end
  end

  defp filter_admin_show_all(query, %CommissionFilter{} = filter) do
    if filter.admin_show_all do
      query
      |> where(
        [
          commission: c,
          artist: artist,
          current_user: u
        ],
        :admin in u.roles or :mod in u.roles or c.client_id == u.id or artist.id == u.id
      )
    else
      query
      |> where(
        [commission: c, artist: artist, current_user: u],
        c.client_id == u.id or artist.id == u.id
      )
    end
  end

  @doc """
  Gets a single commission for a studio.

  Raises `Ecto.NoResultsError` if the Commission does not exist.
  """
  def get_commission!(public_id, current_user) do
    Repo.one!(
      from c in Commission,
        left_join: s in assoc(c, :studio),
        left_join: artist in assoc(s, :artists),
        join: u in User,
        on: u.id == ^current_user.id,
        where:
          c.public_id == ^public_id and
            (:admin in u.roles or
               :mod in u.roles or
               c.client_id == ^current_user.id or
               ^current_user.id == artist.id),
        preload: [
          :studio,
          events: [invoice: [], attachments: [:upload, :thumbnail, :preview]],
          line_items: [:option],
          offering: [:options, :studio]
        ]
    )
  end

  @doc """
  Gets just the `public_id` for a commission.
  """
  def get_public_id!(commission_id) do
    Repo.one!(
      from c in Commission,
        where: c.id == ^commission_id,
        select: %{
          public_id: c.public_id
        }
    ).public_id
  end

  @doc """
  Has the given user archived this commission?
  """
  def archived?(%User{} = user, %Commission{} = commission) do
    from(archived in CommissionArchived,
      where:
        archived.user_id == ^user.id and archived.commission_id == ^commission.id and
          archived.archived != false
    )
    |> Repo.exists?()
  end

  @doc """
  Is the commission currently open?

  NOTE: This expects the commission to be in its latest state.
  """
  def commission_open?(%Commission{status: :withdrawn}), do: false
  def commission_open?(%Commission{status: :rejected}), do: false
  def commission_open?(%Commission{status: :approved}), do: false
  def commission_open?(%Commission{}), do: true

  @doc """
  Gets an attachment with preloaded uploads data.
  """
  def get_attachment_if_allowed!(commission_id, upload_id, user) do
    Repo.one!(
      from ea in EventAttachment,
        join: ul in assoc(ea, :upload),
        left_join: thumb in assoc(ea, :thumbnail),
        left_join: prev in assoc(ea, :preview),
        join: e in assoc(ea, :event),
        join: c in assoc(e, :commission),
        join: s in assoc(c, :studio),
        join: artist in assoc(s, :artists),
        left_join: i in assoc(e, :invoice),
        # Either the user is a studio member
        # Or the user is the client
        # And the invoice requires payment to view attachments and has succeeded
        # Or the invoice doesn't require payment to view attachments
        where:
          c.public_id == ^commission_id and
            ul.id == ^upload_id and
            (artist.id == ^user.id or
               (c.client_id == ^user.id and
                  ((i.required and i.status == :succeeded) or not i.required or is_nil(i.required)))),
        select: ea,
        select_merge: %{
          upload: ul,
          thumbnail: thumb,
          preview: prev
        }
    )
  end

  @doc """
  Calculates the total currently deposited amount for a commission.
  """
  def deposited_amount(
        %User{id: user_id, roles: roles} = actor,
        %Commission{client_id: client_id} = comm,
        current_user_member?
      )
      when user_id != client_id and current_user_member? == false do
    if :admin in roles || :mod in roles do
      deposited_amount(actor, comm, true)
    else
      {:error, :unauthorized}
    end
  end

  def deposited_amount(_, %Commission{} = commission, _) do
    if Ecto.assoc_loaded?(commission.events) do
      Enum.reduce(
        commission.events,
        %{},
        fn event, acc ->
          if event.invoice && event.invoice.status in [:succeeded, :released] do
            current =
              Map.get(
                acc,
                event.invoice.amount.currency,
                Money.new(0, event.invoice.amount.currency)
              )

            Map.put(acc, event.invoice.amount.currency, Money.add(current, event.invoice.amount))
          else
            acc
          end
        end
      )
    else
      deposits =
        from(
          i in Invoice,
          where:
            i.commission_id == ^commission.id and
              i.status in [:succeeded, :released],
          select: i.amount
        )
        |> Repo.all()

      Enum.reduce(
        deposits,
        %{},
        fn dep, acc ->
          current = Map.get(acc, dep.currency, Money.new(0, dep.currency))
          Map.put(acc, dep.currency, Money.add(current, dep))
        end
      )
    end
  end

  @doc """
  Calculates total tips so far for a commission.
  """
  def tipped_amount(
        %User{id: user_id, roles: roles} = actor,
        %Commission{client_id: client_id} = comm,
        current_user_member?
      )
      when user_id != client_id and current_user_member? == false do
    if :admin in roles || :mod in roles do
      tipped_amount(actor, comm, true)
    else
      {:error, :unauthorized}
    end
  end

  def tipped_amount(_, %Commission{} = commission, _) do
    if Ecto.assoc_loaded?(commission.events) do
      Enum.reduce(
        commission.events,
        %{},
        fn event, acc ->
          if event.invoice && event.invoice.status in [:succeeded, :released] do
            current =
              Map.get(
                acc,
                event.invoice.tip.currency,
                Money.new(0, event.invoice.tip.currency)
              )

            Map.put(acc, event.invoice.tip.currency, Money.add(current, event.invoice.tip.amount))
          else
            acc
          end
        end
      )
    else
      deposits =
        from(
          i in Invoice,
          where:
            i.commission_id == ^commission.id and
              i.status == :succeeded,
          select: i.tip
        )
        |> Repo.all()

      Enum.reduce(
        deposits,
        %{},
        fn dep, acc ->
          current = Map.get(acc, dep.currency, Money.new(0, dep.currency))
          Map.put(acc, dep.currency, Money.add(current, dep))
        end
      )
    end
  end

  @doc """
  Calculates the total commission cost based on the current line items.
  """
  def line_item_estimate(line_items) do
    Enum.reduce(
      line_items,
      %{},
      fn item, acc ->
        current =
          Map.get(
            acc,
            item.amount.currency,
            Money.new(0, item.amount.currency)
          )

        Map.put(acc, item.amount.currency, Money.add(current, item.amount))
      end
    )
  end

  @doc """
  Lists a commission's attachments.
  """
  def list_attachments(%Commission{} = commission) do
    from(ea in EventAttachment,
      join: e in assoc(ea, :event),
      left_join: i in assoc(e, :invoice),
      where:
        e.commission_id == ^commission.id and
          (is_nil(i.required) or
             not i.required or (i.required and i.status == :succeeded)),
      order_by: [desc: e.inserted_at],
      preload: [:upload, :thumbnail, :preview]
    )
    |> Repo.all()
  end

  ## Creation

  @doc """
  Creates a new commission.
  """
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def create_commission(
        %User{} = actor,
        %Studio{} = studio,
        %Offering{} = offering,
        line_items,
        attachments,
        attrs \\ %{}
      ) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = actor |> Repo.preload(:disable_info, force: true)
        studio = studio |> Repo.reload()
        offering = offering |> Repo.reload()
        available_proposal_count = Offerings.offering_available_proposals(offering)
        available_slot_count = Offerings.offering_available_slots(offering, true)

        cond do
          Studios.user_blocked?(studio, actor) ->
            {:error, :blocked}

          actor.disable_info ->
            {:error, :disabled}

          studio.archived_at ->
            {:error, :studio_archived}

          offering.archived_at ->
            {:error, :offering_archived}

          !offering.open ->
            {:error, :offering_closed}

          is_nil(actor.confirmed_at) ->
            {:error, :not_confirmed}

          available_proposal_count && available_proposal_count <= 0 ->
            {:error, :no_proposals_available}

          available_slot_count && available_slot_count <= 0 ->
            {:error, :no_slots_available}

          true ->
            offering = maybe_close_offering!(offering, available_proposal_count)
            insert_commission(actor, studio, offering, line_items, attachments, attrs)
        end
      end)

    ret
  end

  defp maybe_close_offering!(offering, available_proposal_count) do
    # Make sure we close the offering if we're out of proposals.
    close = !is_nil(available_proposal_count) && available_proposal_count <= 1

    if close do
      {:ok, offering} =
        Offerings.update_offering(Accounts.system_user(), offering, %{open: false}, nil)

      offering
    else
      offering
    end
  end

  defp insert_commission(actor, studio, offering, line_items, attachments, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        comm_changeset =
          %Commission{
            studio: studio,
            offering: offering,
            client: actor,
            line_items: line_items,
            terms: offering.terms || studio.default_terms
          }
          |> Commission.creation_changeset(attrs)

        with {:ok, %Commission{} = commission} <- Repo.insert(comm_changeset),
             _ <- Notifications.subscribe_user!(actor, commission),
             {:ok, _} <-
               create_event(
                 :comment,
                 actor,
                 commission,
                 true,
                 attachments,
                 %{
                   text: Map.get(attrs, "description", "")
                 },
                 false
               ) do
          commission =
            commission |> Repo.preload(events: [attachments: [:upload, :thumbnail, :preview]])

          Notifications.new_commission(commission, actor)
          {:ok, commission}
        end
      end)

    ret
  end

  @doc """
  Creates a event.
  """
  def create_event(
        type,
        actor,
        commission,
        current_user_member?,
        attachments,
        attrs,
        notify \\ true
      )

  def create_event(
        type,
        %User{id: user_id, roles: roles} = actor,
        %Commission{client_id: client_id} = comm,
        current_user_member?,
        attachments,
        attrs,
        notify
      )
      when user_id != client_id and current_user_member? == false do
    if :admin in roles || :mod in roles do
      create_event(type, actor, comm, true, attachments, attrs, notify)
    else
      {:error, :unauthorized}
    end
  end

  def create_event(
        type,
        %User{} = actor,
        %Commission{} = commission,
        _current_user_member?,
        attachments,
        attrs,
        notify
      )
      when is_atom(type) do
    {:ok, ret} =
      Repo.transaction(fn ->
        changeset =
          %Event{
            type: type,
            commission_id: commission.id,
            actor_id: actor.id
          }
          |> Event.changeset(attrs)

        with :ok <-
               (if commission.studio_id &&
                     Studios.user_blocked?(%Studio{id: commission.studio_id}, actor) do
                  {:error, :blocked}
                else
                  :ok
                end),
             {:ok, event} <- Repo.insert(changeset),
             :ok <- add_attachments!(event, attachments) do
          event = event |> Repo.preload(attachments: [:upload, :thumbnail, :preview])

          if notify do
            Notifications.new_commission_events(commission, [%{event | invoice: nil}], actor)
          end

          {:ok, event}
        end || {:error, :event_failure}
      end)

    ret
  end

  ## Edit/Update

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def check_actor_edit_access(%User{} = actor, %Commission{} = commission) do
    actor = actor |> Repo.reload() |> Repo.preload(:disable_info, force: true)

    cond do
      !is_nil(actor.disable_info) ->
        {:error, :disabled}

      commission.studio_id && Studios.user_blocked?(%Studio{id: commission.studio_id}, actor) ->
        {:error, :blocked}

      actor.id != commission.client_id &&
        !(commission.studio_id &&
              Studios.is_user_in_studio?(actor, %Studio{id: commission.studio_id})) &&
        :admin not in actor.roles &&
          :mod not in actor.roles ->
        {:error, :unauthorized}

      true ->
        {:ok, actor}
    end
  end

  @doc """
  Update user's archival state for a commission.
  """
  def update_archived(%User{} = actor, %Commission{} = commission, archived?) do
    %CommissionArchived{user: actor, commission: commission, archived: archived?}
    |> Repo.insert(
      on_conflict: {:replace, [:archived]},
      conflict_target: [:user_id, :commission_id],
      returning: true
    )
  end

  @doc """
  Updates a commission's title.
  """
  def update_title(%User{} = actor, %Commission{} = commission, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        commission = commission |> Repo.reload()

        with {:ok, actor} <- check_actor_edit_access(actor, commission) do
          old_title = commission.title

          commission
          |> Commission.update_title_changeset(attrs)
          |> Repo.update(returning: true)
          |> case do
            {:ok, commission} ->
              Notifications.commission_title_changed(commission, actor)

              with {:ok, _} <-
                     create_event(:title_changed, actor, commission, true, [], %{
                       text: old_title
                     }) do
                {:ok, commission}
              end

            {:error, err} ->
              {:error, err}
          end
        end
      end)

    ret
  end

  @doc """
  Updates a commission's status, taking account legal status changes based on whether a user is a studio member or a client.
  """
  def update_status(%User{} = actor, %Commission{} = commission, status) do
    {:ok, ret} =
      Repo.transaction(fn ->
        with {:ok, actor} <- check_actor_edit_access(actor, commission) do
          changeset = Repo.reload(commission) |> Commission.status_changeset(%{status: status})

          check_status_transition!(actor, commission, changeset.changes.status)

          with {:ok, commission} <- changeset |> Repo.update() do
            if commission.status == :accepted do
              offering = Repo.preload(commission, :offering).offering
              available_slot_count = Offerings.offering_available_slots(offering, true)

              # Make sure we close the offering if we're out of slots.
              close = !is_nil(available_slot_count) && available_slot_count <= 0

              if close do
                {:ok, _} =
                  Offerings.update_offering(Accounts.system_user(), offering, %{open: false}, nil)
              end
            end

            if commission.status == :approved do
              # Release any successful deposits.
              from(i in Invoice,
                where: i.commission_id == ^commission.id and i.status == :succeeded
              )
              |> Repo.update_all(set: [status: :released])

              from(e in Event,
                join: i in assoc(e, :invoice),
                where: i.commission_id == ^commission.id and i.status == :released,
                select: e,
                preload: [:actor, invoice: [], attachments: [:upload, :thumbnail, :preview]]
              )
              |> Repo.all()
              |> Enum.each(fn ev ->
                Notifications.commission_event_updated(commission, ev, actor)
              end)
            end

            # current_user_member? is checked as part of check_status_transition!
            with {:ok, _event} <-
                   create_event(:status, actor, commission, true, [], %{status: status}) do
              Notifications.commission_status_changed(commission, actor)

              {:ok, commission}
            end
          end
        end
      end)

    ret
  end

  defp check_status_transition!(
         %User{} = actor,
         %Commission{client_id: client_id, studio_id: studio_id, status: current_status},
         new_status
       ) do
    {:ok, _} =
      Repo.transaction(fn ->
        actor_member? =
          !is_nil(studio_id) && Studios.is_user_in_studio?(actor, %Studio{id: studio_id})

        true =
          status_transition_allowed?(
            actor_member? || :admin in actor.roles || :mod in actor.roles,
            client_id == actor.id || :admin in actor.roles || :mod in actor.roles,
            current_status,
            new_status
          )
      end)

    :ok
  end

  # Transition changes studios can make
  defp status_transition_allowed?(artist?, client?, from, to)

  defp status_transition_allowed?(true, _, :submitted, :accepted), do: true
  defp status_transition_allowed?(true, _, :submitted, :rejected), do: true
  defp status_transition_allowed?(true, _, :accepted, :in_progress), do: true
  defp status_transition_allowed?(true, _, :accepted, :paused), do: true
  defp status_transition_allowed?(true, _, :accepted, :ready_for_review), do: true
  defp status_transition_allowed?(true, _, :in_progress, :paused), do: true
  defp status_transition_allowed?(true, _, :in_progress, :waiting), do: true
  defp status_transition_allowed?(true, _, :in_progress, :ready_for_review), do: true
  defp status_transition_allowed?(true, _, :paused, :in_progress), do: true
  defp status_transition_allowed?(true, _, :paused, :waiting), do: true
  defp status_transition_allowed?(true, _, :waiting, :in_progress), do: true
  defp status_transition_allowed?(true, _, :waiting, :paused), do: true
  defp status_transition_allowed?(true, _, :waiting, :ready_for_review), do: true
  defp status_transition_allowed?(true, _, :ready_for_review, :in_progress), do: true
  defp status_transition_allowed?(true, _, :approved, :accepted), do: true
  defp status_transition_allowed?(true, _, :withdrawn, :accepted), do: true
  defp status_transition_allowed?(true, _, :rejected, :accepted), do: true

  # Transition changes clients can make
  defp status_transition_allowed?(_, true, :ready_for_review, :approved), do: true
  defp status_transition_allowed?(_, true, :withdrawn, :submitted), do: true

  # Either party can withdraw a commission
  defp status_transition_allowed?(_, _, _, :withdrawn), do: true

  # Everything else is a no from me, Bob.
  defp status_transition_allowed?(_, _, _, _), do: false

  @doc """
  Adds a new line item to an existing commission. Only studio members and
  admins/mods can do this.
  """
  def add_line_item(actor, commission, option, current_user_member?)

  def add_line_item(actor, commission, option, false) do
    if :admin in actor.roles || :mod in actor.roles do
      add_line_item(actor, commission, option, true)
    else
      {:error, :unauthorized}
    end
  end

  def add_line_item(%User{} = actor, %Commission{} = commission, option, true) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = Repo.reload(actor)

        if Studios.is_user_in_studio?(actor, %Studio{id: commission.studio_id}) ||
             :admin in actor.roles ||
             :mod in actor.roles do
          line_item =
            case option do
              %OfferingOption{} ->
                %LineItem{
                  commission_id: commission.id,
                  option: option,
                  amount: option.price,
                  name: option.name,
                  description: option.description
                }

              %{amount: amount, name: name, description: description} ->
                %LineItem{
                  commission_id: commission.id,
                  amount: amount,
                  name: name,
                  description: description
                }
            end

          with {:ok, line_item} <- Repo.insert(line_item),
               %LineItem{} = line_item <- line_item |> Repo.preload(:option),
               line_items <- commission.line_items ++ [line_item],
               %Commission{} = commission <- %{commission | line_items: line_items},
               {:ok, event} <-
                 create_event(:line_item_added, actor, commission, true, [], %{
                   amount: line_item.amount,
                   text: line_item.name
                 }) do
            Notifications.commission_line_items_changed(commission, actor)
            {:ok, {commission, [event]}}
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Adds a comment to a commission.
  """
  def add_comment(
        %User{} = actor,
        %Commission{} = commission,
        current_user_member?,
        attachments,
        text
      ) do
    create_event(
      :comment,
      actor,
      commission,
      current_user_member?,
      attachments,
      %{"text" => text}
    )
  end

  @doc """
  Adds a the given attachments to the event.
  """
  def add_attachments!(%Event{} = event, attachments) do
    {:ok, _} =
      Repo.transaction(fn ->
        Enum.each(attachments, fn upload ->
          {:ok, thumbnail} =
            if Uploads.image?(upload) || Uploads.video?(upload) do
              Thumbnailer.thumbnail(
                upload,
                target_size: "5kb",
                dimensions: "128x128",
                callback: [
                  Notifications,
                  :commission_event_updated,
                  [event.commission_id, event.id]
                ]
              )
            else
              {:ok, nil}
            end

          {:ok, preview} =
            if Uploads.image?(upload) || Uploads.video?(upload) do
              Thumbnailer.thumbnail(
                upload,
                dimensions: "1200",
                name: "preview.jpg",
                callback: [
                  Notifications,
                  :commission_event_updated,
                  [event.commission_id, event.id]
                ]
              )
            else
              {:ok, nil}
            end

          %EventAttachment{
            event: event,
            upload: upload,
            thumbnail: thumbnail,
            preview: preview
          }
          |> Repo.insert!()
        end)
      end)

    :ok
  end

  @doc """
  Removes a new line item from an existing commission. Only studio members and
  admins/mods can do this.
  """
  def remove_line_item(actor, commission, line_item, current_user_member?)

  def remove_line_item(actor, commission, line_item, false) do
    if :admin in actor.roles || :mod in actor.roles do
      remove_line_item(actor, commission, line_item, true)
    else
      {:error, :unauthorized}
    end
  end

  def remove_line_item(%User{} = actor, %Commission{} = commission, line_item, true) do
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = Repo.reload(actor)

        if Studios.is_user_in_studio?(actor, %Studio{id: commission.studio_id}) ||
             :admin in actor.roles ||
             :mod in actor.roles do
          with {:ok, _} <- Repo.delete(line_item),
               line_items <- Enum.filter(commission.line_items, &(&1.id != line_item.id)),
               %Commission{} = commission <- %{commission | line_items: line_items},
               {:ok, event} <-
                 create_event(:line_item_removed, actor, commission, true, [], %{
                   amount: line_item.amount,
                   text: line_item.name
                 }) do
            Notifications.commission_line_items_changed(commission, actor)
            {:ok, {commission, [event]}}
          end
        else
          {:error, :unauthorized}
        end
      end)

    ret
  end

  @doc """
  Updates a event.
  """
  def update_event(%User{} = actor, %Event{} = event, attrs) do
    {:ok, ret} =
      Repo.transaction(fn ->
        commission = Repo.one(Ecto.assoc(event, :commission))

        with {:ok, actor} <- check_actor_edit_access(actor, commission) do
          event = event |> Repo.reload(force: true) |> Repo.preload(:commission)

          original_text = event.text
          changeset = Event.changeset(event, attrs)

          with {:ok, event} <- Repo.update(changeset, returning: true),
               %Event{} = event <-
                 Repo.preload(event, [
                   :actor,
                   invoice: [],
                   attachments: [:upload, :thumbnail, :preview]
                 ]) do
            if Ecto.Changeset.fetch_change(changeset, :text) == :error do
              Notifications.commission_event_updated(commission, event, actor)
              {:ok, event}
            else
              # If we're editing the event's text, we want to create a
              # history entry for it for recordkeeping.
              history = %CommentHistory{
                text: original_text,
                written_at: event.updated_at,
                event_id: event.id,
                changed_by_id: actor.id
              }

              with {:ok, _} <- Repo.insert(history) do
                Notifications.commission_event_updated(commission, event, actor)
                {:ok, event}
              end
            end
          end
        end
      end)

    ret
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.
  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` specifically for tracking event text changes.
  """
  def change_event_text(%Event{} = event, attrs \\ %{}) do
    Event.text_changeset(event, attrs)
  end

  ## Deletion

  @doc """
  Deletes an attachment from a comment.
  """
  def delete_attachment(
        %User{} = actor,
        %Commission{} = commission,
        %Event{} = event,
        %EventAttachment{} = event_attachment
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:delete_upload, fn _, _ ->
      if event_attachment.upload_id do
        UploadDeleter.schedule_deletion(%Upload{id: event_attachment.upload_id})
      else
        {:ok, nil}
      end
    end)
    |> Ecto.Multi.run(:delete_preview, fn _, _ ->
      if event_attachment.preview_id do
        UploadDeleter.schedule_deletion(%Upload{id: event_attachment.preview_id},
          keep_original: true
        )
      else
        {:ok, nil}
      end
    end)
    |> Ecto.Multi.run(:delete_thumbnail, fn _, _ ->
      if event_attachment.thumbnail_id do
        UploadDeleter.schedule_deletion(%Upload{id: event_attachment.thumbnail_id},
          keep_original: true
        )
      else
        {:ok, nil}
      end
    end)
    |> Ecto.Multi.delete(:delete_event_attachment, event_attachment)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        new_attachments = Enum.reject(event.attachments, &(&1.id == event_attachment.id))

        Notifications.commission_event_updated(
          commission,
          %{event | attachments: new_attachments},
          actor
        )

        {:ok, event_attachment}

      {:error, _, error, _} ->
        {:error, error}
    end
  end
end
