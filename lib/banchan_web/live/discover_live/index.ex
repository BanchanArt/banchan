defmodule BanchanWeb.DiscoverLive.Index do
  @moduledoc """
  General search and discovery page.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.{Form, LivePatch}
  alias Surface.Components.Form.{Field, Submit}
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Form.Select

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.DiscoverLive.Components.{Offerings, Studios}

  @impl true
  def handle_params(params, uri, socket) do
    socket = param_filters(socket, params)
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("change", search, socket) do
    if search["_target"] == ["sort_by"] do
      sort_by = search["sort_by"] && String.to_existing_atom(search["sort_by"])
      params = []

      params =
        case {sort_by, socket.assigns.type} do
          {:homepage, "studios"} ->
            params

          {:featured, "offerings"} ->
            params

          {nil, _} ->
            params

          {sort_by, _} ->
            [{:sort_by, sort_by} | params]
        end

      params =
        if socket.assigns.query && socket.assigns.query != "" do
          [{:q, socket.assigns.query} | params]
        else
          params
        end

      {:noreply,
       socket
       |> push_patch(
         to:
           Routes.discover_index_path(
             Endpoint,
             :index,
             socket.assigns.type || "offerings",
             params
           )
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit", search, socket) do
    sort_by = search["sort_by"] && String.to_existing_atom(search["sort_by"])

    params = []

    params =
      if search["query"] && search["query"] != "" do
        [{:q, search["query"]} | params]
      else
        params
      end

    params =
      case {sort_by, socket.assigns.type} do
        {:homepage, "studios"} ->
          params

        {:featured, "offerings"} ->
          params

        {nil, _} ->
          params

        {sort_by, _} ->
          [{:sort_by, sort_by} | params]
      end

    {:noreply,
     socket
     |> push_patch(
       to:
         Routes.discover_index_path(Endpoint, :index, socket.assigns.type || "offerings", params)
     )}
  end

  defp param_filters(socket, params) do
    query = params["q"]
    type = params["type"]
    order_by = params["sort"] && String.to_existing_atom(params["order_by"])

    socket
    |> assign(query: query, type: type, order_by: order_by)
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <h1 class="text-3xl">Discover</h1>
      <div class="divider" />
      <div class="tabs tabs-boxed flex flex-nowrap max-w-xl mx-auto">
        <div class={"tab tab-lg flex-1", "tab-active": @type not in ["studios", "offerings"]}>
          <LivePatch to={Routes.discover_index_path(Endpoint, :index)}>Explore</LivePatch>
        </div>
        <div class={"tab tab-lg flex-1", "tab-active": @type == "offerings"}>
          <LivePatch to={Routes.discover_index_path(Endpoint, :index, "offerings")}>Offerings</LivePatch>
        </div>
        <div class={"tab tab-lg flex-1", "tab-active": @type == "studios"}>
          <LivePatch to={Routes.discover_index_path(Endpoint, :index, "studios")}>Studios</LivePatch>
        </div>
      </div>
      <div class="form-control mx-auto max-w-3xl py-4">
        <Form for={:search} change="change" submit="submit">
          <div class="flex flex-row flex-nowrap grow">
            {#if @type == "studios"}
              <Select
                name={:sort_by}
                class="select select-bordered select-lg"
                selected={@order_by}
                options={
                  "For You": :homepage,
                  Newest: :newest,
                  Earliest: :oldest,
                  Followers: :followers
                }
              />
            {#elseif @type == "offerings"}
              <Select
                name={:sort_by}
                class="select select-bordered select-lg"
                selected={@order_by}
                options={
                  "For You": :featured,
                  Newest: :newest,
                  Earliest: :oldest,
                  Cheapest: :price_low,
                  Fanciest: :price_high
                }
              />
            {/if}
            <Field name={:query}>
              <TextInput
                name={:query}
                value={@query}
                class="grow w-full input input-bordered input-lg"
                opts={
                  placeholder:
                    case @type do
                      "studios" -> "Search for studios..."
                      "offerings" -> "Search for offerings..."
                      _ -> "Search for offerings..."
                    end
                }
              />
            </Field>
            <Submit class="btn btn-round btn-lg">
              <i class="fas fa-search" />
            </Submit>
          </div>
        </Form>
      </div>
      {#if @type == "studios"}
        <Studios id="studios" query={@query} order_by={@order_by} />
      {#elseif @type == "offerings"}
        <Offerings id="offerings" query={@query} order_by={@order_by} />
      {#else}
        <div class="px-2 flex flex-row items-end">
          <div class="text-xl grow">
            Selected Offerings
          </div>
          <div class="text-md">
            <LivePatch
              class="hover:link text-primary"
              to={Routes.discover_index_path(Endpoint, :index, "offerings")}
            >Discover More</LivePatch>
          </div>
        </div>
        <div class="divider" />
        <Offerings id="offerings" page_size={4} infinite={false} />
        <div class="pt-10 px-2 flex flex-row items-end">
          <div class="text-xl grow">
            Selected Studios
          </div>
          <div class="text-md">
            <LivePatch
              class="hover:link text-primary"
              to={Routes.discover_index_path(Endpoint, :index, "studios")}
            >Discover More</LivePatch>
          </div>
        </div>
        <div class="divider" />
        <Studios id="studios" page_size={3} infinite={false} />
      {/if}
    </Layout>
    """
  end
end
