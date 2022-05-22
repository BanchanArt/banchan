defmodule BanchanWeb.CommissionLive do
  @moduledoc """
  Artist dashboard
  """
  use BanchanWeb, :surface_view

  alias Banchan.{Commissions, Studios}

  alias Surface.Components.LivePatch

  alias BanchanWeb.CommissionLive.Components.CommissionRow
  alias BanchanWeb.Components.Layout

  alias BanchanWeb.CommissionLive.Components.Commissions.{
    CommentBox,
    DraftBox,
    StatusBox,
    SummaryEditor,
    Timeline
  }

  @impl true
  def handle_params(params, uri, socket) do
    if connected?(socket) do
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
            comm =
              if Map.has_key?(socket.assigns, :commission) &&
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
              current_user_member?:
                Studios.is_user_in_studio(socket.assigns.current_user, comm.studio_id)
            )

          _ ->
            assign(socket, commission: nil, current_user_member?: false)
        end

      {:noreply, socket |> assign(:uri, uri) |> assign(:connected, true)}
    else
      {:noreply, assign(socket, :connected, false)}
    end
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
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      {#if !@connected}
        Loading
      {#else}
        <div class="flex flex-col grow max-h-full">
          <div class="flex flex-row grow">
            <div class={"flex md:basis-1/4", "hidden md:flex": @commission}>
              <ul class="divide-y flex-grow flex flex-col">
                {#for result <- @results.entries}
                  <li>
                    <CommissionRow
                      result={result}
                      highlight={@commission && @commission.public_id == result.commission.public_id}
                    />
                  </li>
                {/for}
              </ul>
            </div>
            {#if @commission}
              <div class="md:container md:basis-3/4">
                <h1 class="text-3xl pt-4 px-4">
                  <LivePatch class="md:hidden p-2" to={Routes.commission_path(Endpoint, :index)}>
                    <i class="fas fa-arrow-left text-2xl" />
                  </LivePatch>
                  {@commission.title}
                </h1>
                <div class="divider" />
                <div class="p-2">
                  <div class="flex flex-col md:grid md:grid-cols-3 gap-4">
                    <div class="flex flex-col md:order-2">
                      <DraftBox
                        id="draft-box"
                        current_user={@current_user}
                        current_user_member?={@current_user_member?}
                        commission={@commission}
                      />
                      <div class="divider" />
                      <SummaryEditor
                        id="summary-editor"
                        current_user={@current_user}
                        current_user_member?={@current_user_member?}
                        commission={@commission}
                        allow_edits={@current_user_member?}
                      />
                    </div>
                    <div class="divider md:hidden" />
                    <div class="flex flex-col md:col-span-2 md:order-1">
                      <Timeline
                        uri={@uri}
                        commission={@commission}
                        current_user={@current_user}
                        current_user_member?={@current_user_member?}
                      />
                      <div class="divider" />
                      <div class="flex flex-col gap-4">
                        <StatusBox
                          id="action-box"
                          commission={@commission}
                          current_user={@current_user}
                          current_user_member?={@current_user_member?}
                        />
                        <CommentBox
                          id="comment-box"
                          commission={@commission}
                          actor={@current_user}
                          current_user_member?={@current_user_member?}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            {/if}
          </div>
        </div>
      {/if}
    </Layout>
    """
  end
end
