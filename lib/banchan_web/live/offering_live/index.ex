defmodule BanchanWeb.OfferingLive.Index do
  @moduledoc """
  Index page for listing/sorting offerings.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.Select

  alias BanchanWeb.Components.{InfiniteScroll, Layout}

  alias BanchanWeb.StudioLive.Components.OfferingCard

  @impl true
  def mount(_params, _session, socket) do
    socket = socket |> assign(order_by: :featured)
    {:ok, socket |> assign(offerings: list_offerings(socket))}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.offerings.total_entries >
         socket.assigns.offerings.page_number * socket.assigns.offerings.page_size do
      {:noreply, fetch(socket.assigns.offerings.page_number + 1, socket)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change_sort", %{"sort_by" => %{"sort_by" => sort_by}}, socket) do
    sort_by = String.to_existing_atom(sort_by)
    socket = socket |> assign(order_by: sort_by)
    socket = socket |> assign(offerings: list_offerings(socket, 1))
    {:noreply, socket}
  end

  defp list_offerings(socket, page \\ 1) do
    Offerings.list_offerings(
      order_by: socket.assigns.order_by,
      page_size: 24,
      page: page
    )
  end

  defp fetch(page, %{assigns: %{offerings: offerings}} = socket) do
    socket
    |> assign(
      :offerings,
      %{
        offerings
        | page_number: page,
          entries: offerings.entries ++ list_offerings(socket, page).entries
      }
    )
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <div class="flex flex-row sticky items-end">
        <h1 class="text-3xl grow">Offerings</h1>
        <Form for={:sort_by} change="change_sort">
          <Select
            name={:sort_by}
            show_label={false}
            options={
              "For You": :featured,
              Newest: :newest,
              Earliest: :oldest
            }
          />
        </Form>
      </div>
      <div class="divider" />
      <div class="offering-list grid grid-cols-2 sm:gap-2 sm:grid-cols-3 md:grid-cols-4 xl:grid-cols-5 auto-rows-fr">
        {#for {offering, idx} <- Enum.with_index(@offerings)}
          <OfferingCard id={"offering-#{idx}"} current_user={@current_user} offering={offering} />
        {/for}
      </div>
      <InfiniteScroll
        id="offerings-infinite-scroll"
        page={@offerings.page_number}
        load_more="load_more"
      />
    </Layout>
    """
  end
end
