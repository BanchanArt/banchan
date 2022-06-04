defmodule BanchanWeb.CommissionLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias Banchan.{Commissions, Notifications, Studios}

  alias BanchanWeb.CommissionLive.Components.CommissionRow
  alias BanchanWeb.Components.Layout

  alias BanchanWeb.CommissionLive.Components.Commission

  @impl true
  def handle_params(params, uri, socket) do
    if Map.has_key?(socket.assigns, :commission) && socket.assigns.commission do
      Commissions.unsubscribe_from_commission_events(socket.assigns.commission)
    end

    socket =
      socket
      |> assign(
        :results,
        Commissions.list_commission_data_for_dashboard(
          socket.assigns.current_user,
          page(params),
          sort(params)
        )
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
              Commissions.get_commission!(
                commission_id,
                socket.assigns.current_user
              )
            end

          Commissions.subscribe_to_commission_events(comm)

          assign(socket,
            commission: comm,
            subscribed?: Notifications.user_subscribed?(socket.assigns.current_user, comm),
            current_user_member?:
              Studios.is_user_in_studio?(socket.assigns.current_user, %Studios.Studio{
                id: comm.studio_id
              })
          )

        _ ->
          assign(socket, commission: nil, current_user_member?: false)
      end

    {:noreply, socket |> assign(:uri, uri)}
  end

  defp sort(%{"by" => field, "dir" => direction}) when direction in ~w(asc desc) do
    {String.to_existing_atom(direction), String.to_existing_atom(field)}
  end

  defp sort(_other) do
    {:desc, :updated_at}
  end

  defp page(%{"page" => page}) do
    case Integer.parse(page) do
      {p, ""} ->
        p

      _ ->
        1
    end
  end

  defp page(_other) do
    1
  end

  @impl true
  def handle_info(%{event: "new_events", payload: events}, socket) do
    # TODO: I don't know why, but we sometimes get two `new_events` messages
    # for a single event addition. So we have to dedup here just in case until
    # that bug is... fixed? If it's even a bug vs something expected?
    events = socket.assigns.commission.events ++ events

    events =
      events
      |> Enum.dedup_by(& &1.public_id)
      |> Enum.sort(&(Timex.diff(&1.inserted_at, &2.inserted_at) < 0))

    commission = %{socket.assigns.commission | events: events}
    {:noreply, assign(socket, commission: commission)}
  end

  def handle_info(%{event: "new_status", payload: status}, socket) do
    commission = %{socket.assigns.commission | status: status}
    {:noreply, assign(socket, commission: commission)}
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
    {:noreply, assign(socket, commission: commission)}
  end

  def handle_info(%{event: "line_items_changed", payload: line_items}, socket) do
    {:noreply,
     socket |> assign(commission: %{socket.assigns.commission | line_items: line_items})}
  end

  @impl true
  def handle_event("toggle_subscribed", _, socket) do
    if socket.assigns.subscribed? do
      Notifications.unsubscribe_user!(socket.assigns.current_user, socket.assigns.commission)
    else
      Notifications.subscribe_user!(socket.assigns.current_user, socket.assigns.commission)
    end

    {:noreply, assign(socket, subscribed?: !socket.assigns.subscribed?)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <div class="flex flex-col grow max-h-full">
        <div class="flex flex-row grow md:grow-0">
          <div class={"flex flex-col px-4 sidebar basis-full md:basis-1/4", "hidden md:flex": @commission}>
            <ul class="divide-y-2 divide-neutral-content divide-opacity-10 menu menu-compact">
              {#for result <- @results.entries}
                <CommissionRow
                  result={result}
                  highlight={@commission && @commission.public_id == result.commission.public_id}
                />
              {/for}
            </ul>
          </div>
          {#if @commission}
            <div class="md:container basis-full md:basis-3/4">
              <Commission
                uri={@uri}
                current_user={@current_user}
                commission={@commission}
                subscribed?={@subscribed?}
                current_user_member?={@current_user_member?}
                toggle_subscribed="toggle_subscribed"
              />
            </div>
          {/if}
        </div>
      </div>
    </Layout>
    """
  end
end
