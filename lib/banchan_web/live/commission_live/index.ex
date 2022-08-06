defmodule BanchanWeb.CommissionLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Submit}
  alias Surface.Components.Form.TextInput, as: SurfaceTextInput

  alias Banchan.{Accounts, Commissions, Studios}
  alias Banchan.Commissions.CommissionFilter

  alias BanchanWeb.CommissionLive.Components.CommissionRow
  alias BanchanWeb.Components.{Collapse, InfiniteScroll, Layout}
  alias BanchanWeb.Components.Form.{Checkbox, MultipleSelect, Select, TextInput}

  alias BanchanWeb.CommissionLive.Components.Commission

  @status_options [
    {"Any", nil}
    | Commissions.Common.status_values()
      |> Enum.map(&{Commissions.Common.humanize_status(&1), &1})
  ]

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(
        :filter,
        CommissionFilter.changeset(filter_from_params(params))
      )

    socket =
      socket
      |> assign(page: 1)
      |> assign(order_by: order_from_params(params))
      |> assign(status_options: @status_options)
      |> assign(filter_open: Map.get(socket.assigns, :filter_open, false))

    socket =
      socket
      |> assign(
        :results,
        list_comms(socket)
      )

    socket =
      case params do
        %{"commission_id" => commission_id} ->
          # NOTE: Phoenix LiveView's push_patch has an obnoxious bug with fragments, so
          # we have to manually remove them here.
          # See: https://github.com/phoenixframework/phoenix_live_view/issues/2041
          commission_id = Regex.replace(~r/#.*$/, commission_id, "")

          comm =
            if Map.has_key?(socket.assigns, :commission) && socket.assigns.commission &&
                 socket.assigns.commission.public_id == commission_id do
              socket.assigns.commission
            else
              if Map.has_key?(socket.assigns, :commission) && socket.assigns.commission do
                Commissions.unsubscribe_from_commission_events(socket.assigns.commission)
              end

              Commissions.get_commission!(
                commission_id,
                socket.assigns.current_user
              )
            end

          Commissions.subscribe_to_commission_events(comm)

          users =
            comm.events
            |> Enum.reduce(%{}, fn ev, acc ->
              if Map.has_key?(acc, ev.actor_id) do
                acc
              else
                Map.put(acc, ev.actor_id, Accounts.get_user(ev.actor_id))
              end
            end)

          assign(socket,
            commission: comm,
            users: users,
            current_user_member?:
              !is_nil(comm.studio_id) &&
                Studios.is_user_in_studio?(socket.assigns.current_user, %Studios.Studio{
                  id: comm.studio_id
                })
          )

        _ ->
          assign(socket, commission: nil, users: %{}, current_user_member?: false)
      end

    {:noreply, socket |> assign(:uri, uri)}
  end

  @impl true
  def handle_info(%{event: "new_events", payload: events}, socket) do
    # TODO: I don't know why, but we sometimes get two `new_events` messages
    # for a single event addition. So we have to dedup here just in case until
    # that bug is... fixed? If it's even a bug vs something expected?
    # events = events |> Enum.map(& Repo.preload(&1, [:actor]))
    events = socket.assigns.commission.events ++ events

    users =
      events
      |> Enum.reduce(socket.assigns.users, fn ev, acc ->
        if Map.has_key?(acc, ev.actor_id) do
          acc
        else
          Map.put(acc, ev.actor_id, Accounts.get_user(ev.actor_id))
        end
      end)

    events =
      events
      |> Enum.dedup_by(& &1.public_id)
      |> Enum.sort(&(Timex.diff(&1.inserted_at, &2.inserted_at) < 0))

    commission = %{socket.assigns.commission | events: events}
    Commission.events_updated("commission")
    {:noreply, assign(socket, users: users, commission: commission)}
  end

  def handle_info(%{event: "new_status", payload: status}, socket) do
    if socket.assigns.commission do
      commission = %{socket.assigns.commission | status: status}
      {:noreply, assign(socket, commission: commission)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "new_title", payload: title}, socket) do
    if socket.assigns.commission do
      commission = %{socket.assigns.commission | title: title}
      {:noreply, assign(socket, commission: commission)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "event_updated", payload: event}, socket) do
    events =
      socket.assigns.commission.events
      |> Enum.map(fn ev ->
        if ev.id == event.id do
          event
        else
          ev
        end
      end)

    commission = %{socket.assigns.commission | events: events}
    Commission.events_updated("commission")
    {:noreply, assign(socket, commission: commission)}
  end

  def handle_info(%{event: "line_items_changed", payload: line_items}, socket) do
    {:noreply,
     socket |> assign(commission: %{socket.assigns.commission | line_items: line_items})}
  end

  @impl true
  def handle_event("reset", _, socket) do
    {:noreply,
     socket
     |> push_patch(
       to:
         Routes.commission_path(
           Endpoint,
           :index,
           %CommissionFilter{}
           |> filter_to_params()
         )
     )}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("change", %{"commission_filter" => filter, "_target" => target}, socket) do
    if target == ["commission_filter", "sort_by"] do
      sort_by = filter["sort_by"] && String.to_existing_atom(filter["sort_by"])

      params =
        %CommissionFilter{}
        |> CommissionFilter.changeset(filter)
        |> Ecto.Changeset.apply_changes()
        |> filter_to_params()

      params =
        case sort_by do
          :recently_updated ->
            params

          sort_by ->
            [{:sort_by, sort_by} | params]
        end

      {:noreply,
       socket
       |> push_patch(
         to:
           Routes.commission_path(
             Endpoint,
             :index,
             params
           )
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("filter", %{"commission_filter" => filter}, socket) do
    sort_by = filter["sort_by"] && String.to_existing_atom(filter["sort_by"])

    changeset =
      %CommissionFilter{}
      |> CommissionFilter.changeset(filter)

    if changeset.valid? do
      params =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> filter_to_params()

      params =
        case sort_by do
          :recently_updated ->
            params

          sort_by ->
            [{:sort_by, sort_by} | params]
        end

      {:noreply,
       socket
       |> push_patch(
         to:
           Routes.commission_path(
             Endpoint,
             :index,
             params
           )
       )}
    else
      {:noreply, assign(socket, filter: changeset)}
    end
  end

  def handle_event("toggle_filter", _, socket) do
    Collapse.set_open("filter-options", !socket.assigns.filter_open)
    {:noreply, assign(socket, filter_open: !socket.assigns.filter_open)}
  end

  def handle_event("load_more", _, socket) do
    if socket.assigns.results.total_entries >
         socket.assigns.page * socket.assigns.results.page_size do
      {:noreply, socket |> assign(page: socket.assigns.page + 1) |> fetch()}
    else
      {:noreply, socket}
    end
  end

  defp fetch(%{assigns: %{results: results, page: page}} = socket) do
    socket
    |> assign(
      :results,
      %{
        results
        | entries:
            results.entries ++
              list_comms(socket, page).entries
      }
    )
  end

  defp list_comms(socket, page \\ 1) do
    Commissions.list_commissions(
      socket.assigns.current_user,
      Ecto.Changeset.apply_changes(socket.assigns.filter),
      page: page,
      page_size: 10,
      order_by: socket.assigns.order_by
    )
  end

  defp order_from_params(params) do
    (params["sort_by"] || "recently_updated") |> String.to_existing_atom()
  end

  defp filter_from_params(params) do
    search = params["q"]

    %CommissionFilter{}
    |> CommissionFilter.changeset(
      Enum.into(params, %{
        "search" => search
      })
    )
    |> Ecto.Changeset.apply_changes()
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp filter_to_params(%CommissionFilter{} = filter) do
    params = []

    params =
      if filter.search && filter.search != "" do
        Keyword.put(params, :q, filter.search)
      else
        params
      end

    params =
      if filter.client && filter.client != "" do
        Keyword.put(params, :client, filter.client)
      else
        params
      end

    params =
      if filter.studio && filter.studio != "" do
        Keyword.put(params, :studio, filter.studio)
      else
        params
      end

    params =
      if filter.show_archived do
        Keyword.put(params, :show_archived, filter.show_archived)
      else
        params
      end

    params =
      if filter.admin_show_all do
        Keyword.put(params, :admin_show_all, filter.admin_show_all)
      else
        params
      end

    params =
      if filter.statuses && !Enum.empty?(filter.statuses) do
        Keyword.put(params, :statuses, filter.statuses)
      else
        params
      end

    params
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      {#if !@commission}
        <h1 class="text-3xl">My Commissions</h1>
        <div class="divider" />
      {/if}
      <div class="flex flex-row grow xl:grow-0">
        <div class={"flex flex-col pt-4 sidebar basis-full", hidden: @commission}>
          <Form
            for={@filter}
            change="change"
            submit="filter"
            class="form-control px-4 mx-auto max-w-3xl pb-6 w-full md:w-content"
          >
            <Field class="w-full input-group grow" name={:search}>
              <button :on-click="toggle_filter" type="button" class="btn btn-square">
                <i class="fas fa-filter" />
              </button>
              <SurfaceTextInput class="input input-bordered w-full" />
              <Submit class="btn btn-square">
                <i class="fas fa-search" />
              </Submit>
            </Field>
            <Collapse id="filter-options" class="rounded-box">
              <h2 class="text-xl pt-4">
                Additional Filters
              </h2>
              <div class="divider" />
              <TextInput name={:client} />
              <TextInput name={:studio} />
              <MultipleSelect name={:statuses} options={@status_options} />
              <Select
                name={:sort_by}
                class="select select-bordered shrink"
                selected={@order_by}
                options={
                  "Recently Updated": :recently_updated,
                  "Earliest Updated": :oldest_updated,
                  Status: :status
                }
              />
              <div class="py-2">
                <Checkbox label="Show Archived" name={:show_archived} />
              </div>
              {#if :admin in @current_user.roles || :mod in @current_user.roles}
                <div class="py-2">
                  <Checkbox label="Admin: Show All" name={:admin_show_all} />
                </div>
              {/if}
              <div class="grid grid-cols-3 gap-2">
                <Submit label="Apply" class="btn btn-square btn-primary col-span-2 w-full" />
                <button type="button" :on-click="reset" class="btn-btn-square btn-link w-full">Reset</button>
              </div>
            </Collapse>
          </Form>
          {#if Enum.empty?(@results)}
            <div class="py-2 px-4 text-xl">
              No Results
            </div>
          {#else}
            <ul class="menu menu-compact gap-2 p-2">
              {#for result <- @results}
                <CommissionRow
                  result={result}
                  highlight={@commission && @commission.public_id == result.commission.public_id}
                />
              {/for}
            </ul>
            <InfiniteScroll id="commissions-infinite-scroll" page={@page} load_more="load_more" />
          {/if}
        </div>
        {#if @commission}
          <div class="basis-full">
            <Commission
              id="commission"
              uri={@uri}
              users={@users}
              current_user={@current_user}
              commission={@commission}
              current_user_member?={@current_user_member?}
            />
          </div>
        {/if}
      </div>
    </Layout>
    """
  end
end
