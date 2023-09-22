defmodule BanchanWeb.CommissionLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :live_view

  alias Banchan.{Accounts, Commissions, Studios}
  alias Banchan.Commissions.CommissionFilter

  import BanchanWeb.StudioLive.Helpers

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Submit}
  alias Surface.Components.Form.TextInput, as: SurfaceTextInput

  alias BanchanWeb.CommissionLive.Components.CommissionRow
  alias BanchanWeb.Components.{Collapse, Icon, InfiniteScroll, Layout}
  alias BanchanWeb.Components.Form.{Checkbox, ComboBox, TextInput}

  alias BanchanWeb.CommissionLive.Components.Commission

  @status_options Commissions.Common.status_values() |> Enum.map(&{Commissions.Common.humanize_status(&1), &1})

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_params(params, _uri, socket) do
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
            users: users
          )

        _ ->
          assign(socket, commission: nil, users: %{})
      end

    comm = socket.assigns.commission

    socket =
      case params do
        %{"handle" => _} ->
          assign_studio_defaults(params, socket, true, true)

        _ ->
          socket
          |> assign(
            studio: nil,
            current_user_member?:
              !is_nil(comm) &&
                !is_nil(comm.studio_id) &&
                Studios.is_user_in_studio?(socket.assigns.current_user, %Studios.Studio{
                  id: comm.studio_id
                })
          )
      end

    socket =
      socket
      |> assign(
        :context,
        if !is_nil(socket.assigns.studio) && socket.assigns.current_user_member? do
          :studio
        else
          :personal
        end
      )

    socket =
      socket
      |> assign(
        :results,
        list_comms(socket)
      )

    socket =
      Context.put(socket,
        commission: socket.assigns.commission,
        current_user_member?: socket.assigns.current_user_member?
      )

    if !is_nil(comm) && is_nil(socket.assigns.studio) && socket.assigns.current_user_member? do
      studio = Studios.get_studio_by_id!(comm.studio_id)

      # NB(@zkat): This is a less-than-ideal hack and might be confusing to
      # users who decide to commission their own studios, but that's honestly
      # a big corner case, and 99% of the time, if you get linked to a
      # `/commission/<foo>`, you want to be redirected to your studio's
      # context.
      {:noreply,
       socket |> push_navigate(to: ~p"/studios/#{studio.handle}/commissions/#{comm.public_id}")}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info(%{event: "new_events", payload: events}, socket) do
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
      # TODO: I don't know why, but we sometimes get two `new_events` messages
      # for a single event addition. So we have to dedup here just in case until
      # that bug is... fixed? If it's even a bug vs something expected?
      |> Enum.dedup_by(& &1.public_id)
      |> Enum.sort(&(Timex.diff(&1.inserted_at, &2.inserted_at) < 0))

    commission = %{socket.assigns.commission | events: events}
    Commission.events_updated("commission")
    socket = Context.put(socket, commission: commission)
    {:noreply, assign(socket, users: users, commission: commission)}
  end

  def handle_info(%{event: "new_status", payload: status}, socket) do
    if socket.assigns.commission do
      commission = %{socket.assigns.commission | status: status}
      socket = Context.put(socket, commission: commission)
      {:noreply, assign(socket, commission: commission)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "new_title", payload: title}, socket) do
    if socket.assigns.commission do
      commission = %{socket.assigns.commission | title: title}
      socket = Context.put(socket, commission: commission)
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
    socket = Context.put(socket, commission: commission)
    {:noreply, assign(socket, commission: commission)}
  end

  def handle_info(%{event: "line_items_changed", payload: line_items}, socket) do
    commission = %{socket.assigns.commission | line_items: line_items}
    socket = Context.put(socket, commission: commission)
    {:noreply, socket |> assign(commission: commission)}
  end

  @impl true
  def handle_event("reset", _, socket) do
    params =
      %CommissionFilter{}
      |> filter_to_params()

    {:noreply,
     socket
     |> push_patch(
       to:
         if socket.assigns.studio do
           ~p"/studios/#{socket.assigns.studio.handle}/commissions?#{params}"
         else
           ~p"/commissions?#{params}"
         end
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
           if socket.assigns.studio do
             ~p"/studios/#{socket.assigns.studio.handle}/commissions?#{params}"
           else
             ~p"/commissions?#{params}"
           end
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
           if socket.assigns.studio do
             ~p"/studios/#{socket.assigns.studio.handle}/commissions?#{params}"
           else
             ~p"/commissions?#{params}"
           end
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
      exclude_member: is_nil(socket.assigns.studio),
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
        "search" => search,
        "studio" => params["handle"] || params["studio"]
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
    <Layout flashes={@flash} context={@context} studio={@studio}>
      <div class="flex flex-col w-full gap-4 p-4 mx-auto max-w-7xl">
        {#if !@commission}
          <h1 class="text-3xl font-bold">
            {#if @studio}
              Commissions for {@studio.name}
            {#else}
              My Commissions
            {/if}
          </h1>
        {/if}
        <div class="flex flex-row grow xl:grow-0">
          <div class={"flex flex-col sidebar basis-full", hidden: @commission}>
            <Form
              for={@filter}
              change="change"
              submit="filter"
              class="w-full mx-auto form-control md:w-content"
              opts={role: "search"}
            >
              <Field class="w-full input-group grow" name={:search}>
                <button
                  aria-label="Apply commission search filters"
                  :on-click="toggle_filter"
                  type="button"
                  class="btn btn-square"
                >
                  <Icon name="filter" size="4" label="filter" />
                </button>
                <SurfaceTextInput
                  class="w-full input input-bordered"
                  opts={"aria-label": "Search for commissions"}
                />
                <Submit class="btn btn-square" opts={"aria-label": "Search"}>
                  <Icon name="search" size="4" label="search" />
                </Submit>
              </Field>
              <Collapse id="filter-options" class="rounded-box">
                <div class="grid grid-cols-1 gap-4">
                  <h2 class="pt-4 text-xl">
                    Additional Filters
                  </h2>
                  {#unless is_nil(@studio)}
                    <TextInput name={:client} />
                  {/unless}
                  {#if is_nil(@studio)}
                    <TextInput name={:studio} />
                  {/if}
                  <ComboBox multiple name={:statuses} options={@status_options} />
                  <ComboBox
                    name={:sort_by}
                    class="select select-bordered shrink"
                    selected={@order_by}
                    options={
                      "Recently Updated": :recently_updated,
                      "Earliest Updated": :oldest_updated,
                      Status: :status
                    }
                  />
                  <Checkbox label="Show Archived" name={:show_archived} />
                  {#if :admin in @current_user.roles || :mod in @current_user.roles}
                    <Checkbox label="Admin: Show All" name={:admin_show_all} />
                  {/if}
                  <div class="flex flex-row items-center justify-between gap-4">
                    <button type="button" :on-click="reset" class="max-w-xs grow basis-0 btn btn-square btn-ghost">Reset</button>
                    <Submit label="Apply" class="max-w-xs grow basis-0 btn btn-square btn-primary" />
                  </div>
                </div>
              </Collapse>
            </Form>
            <div class="divider" />
            {#if Enum.empty?(@results)}
              <div class="px-4 py-2 text-xl">
                No Results
              </div>
            {#else}
              <ul role="list" class="grid grid-cols-1 gap-4">
                {#for result <- @results}
                  <CommissionRow result={result} />
                {/for}
              </ul>
            {/if}
            <InfiniteScroll id="commissions-infinite-scroll" page={@page} load_more="load_more" />
          </div>
          {#if @commission}
            <div class="basis-full">
              <Commission id="commission" users={@users} commission={@commission} />
            </div>
          {/if}
        </div>
      </div>
    </Layout>
    """
  end
end
