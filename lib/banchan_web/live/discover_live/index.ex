defmodule BanchanWeb.DiscoverLive.Index do
  @moduledoc """
  General search and discovery page.
  """
  use BanchanWeb, :live_view

  alias Surface.Components.{Form, LivePatch}
  alias Surface.Components.Form.{Field, Select, Submit, TextInput}

  alias BanchanWeb.Components.{Icon, Layout}
  alias BanchanWeb.DiscoverLive.Components.{Offerings, Studios}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, order_seed: get_connect_params(socket)["order_seed"] || Prime.generate(16))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    socket = param_filters(socket, params)

    {:noreply, socket}
  end

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
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
    order_by = params["sort_by"] && String.to_existing_atom(params["sort_by"])

    socket
    |> assign(query: query, type: type, order_by: order_by)
  end

  @impl true
  def render(assigns) do
    params =
      if assigns.query && assigns.query != "" do
        %{q: assigns.query}
      else
        %{}
      end

    ~F"""
    <Layout flashes={@flash}>
      <div
        data-order-seed={@order_seed}
        class="flex flex-col items-start w-full gap-0 mx-auto max-w-7xl"
      >
        <div class="flex flex-col items-start w-full gap-4">
          <div class="flex flex-col items-start justify-between w-full gap-4 md:items-center md:flex-row">
            <h1 class="text-3xl">Discover</h1>
            <div class="flex w-full font-semibold border rounded-xl md:w-fit tabs tabs-boxed border-base-content border-opacity-10 flex-nowrap">
              <LivePatch
                class={"tab py-1 px-4 h-fit flex-1 grow md:grow-0", "tab-active": @type == "offerings"}
                to={Routes.discover_index_path(Endpoint, :index, "offerings", params)}
              >
                Offerings
              </LivePatch>
              <LivePatch
                class={"tab py-1 px-4 h-fit flex-1 grow md:grow-0", "tab-active": @type == "studios"}
                to={Routes.discover_index_path(Endpoint, :index, "studios", params)}
              >
                Studios
              </LivePatch>
            </div>
          </div>
          <div class="w-full mx-auto form-control md:w-content">
            <Form for={%{}} as={:search} change="change" submit="submit" class="w-full">
              <div class="flex flex-row w-full gap-4 flex-nowrap grow">
                {#if @type == "studios"}
                  <Select
                    name={:sort_by}
                    class="select select-bordered"
                    selected={@order_by}
                    options={
                      "For You": :homepage,
                      Newest: :newest,
                      Oldest: :oldest,
                      Followers: :followers
                    }
                  />
                {#elseif @type == "offerings"}
                  <Select
                    name={:sort_by}
                    class="select select-bordered"
                    selected={@order_by}
                    options={
                      "For You": :featured,
                      Newest: :newest,
                      Oldest: :oldest,
                      Cheapest: :price_low,
                      Fanciest: :price_high
                    }
                  />
                {/if}
                <Field name={:query} class="w-full">
                  <TextInput
                    name={:query}
                    value={@query}
                    class="w-full grow input input-bordered"
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
                <Submit class="btn btn-round">
                  <Icon name="search" size="4" />
                </Submit>
              </div>
            </Form>
          </div>
        </div>
        <div class="divider" />
        {#if @type == "studios"}
          <Studios
            id="studios"
            suggest_offerings
            current_user={@current_user}
            query={@query}
            order_by={@order_by}
            order_seed={@order_seed}
          />
        {#elseif @type == "offerings"}
          <Offerings
            id="offerings"
            suggest_studios
            current_user={@current_user}
            query={@query}
            order_by={@order_by}
            order_seed={@order_seed}
          />
        {/if}
      </div>
    </Layout>
    """
  end
end
