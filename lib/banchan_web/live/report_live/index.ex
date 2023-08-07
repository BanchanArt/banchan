defmodule BanchanWeb.ReportLive.Index do
  @moduledoc """
  List/search/filter abuse reports.
  """
  use BanchanWeb, :live_view

  alias Banchan.Reports
  alias Banchan.Reports.ReportFilter

  alias Surface.Components.{Form, LiveRedirect}
  alias Surface.Components.Form.{Field, Submit}
  alias Surface.Components.Form.TextInput, as: SurfaceTextInput

  alias BanchanWeb.Components.{Avatar, Collapse, InfiniteScroll, Layout, UserHandle}
  alias BanchanWeb.Components.Form.{MultipleSelect, Select, TextInput}

  @status_options [
    {"Any", nil},
    {"New", :new},
    {"Investigating", :investigating},
    {"Resolved", :resolved}
  ]

  @impl true
  def handle_params(params, _uri, socket) do
    socket =
      socket
      |> assign(
        :filter,
        ReportFilter.changeset(filter_from_params(params))
      )

    socket =
      socket
      |> assign(page: 1)
      |> assign(status_options: @status_options)
      |> assign(filter_open: Map.get(socket.assigns, :filter_open, false))

    socket =
      socket
      |> assign(
        :results,
        list_reports(socket)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _, socket) do
    {:noreply,
     socket
     |> push_patch(
       to:
         Routes.report_index_path(
           Endpoint,
           :index,
           %ReportFilter{}
           |> filter_to_params()
         )
     )}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("change", %{"report_filter" => filter, "_target" => target}, socket) do
    if target == ["commission_filter", "order_by"] do
      params =
        %ReportFilter{}
        |> ReportFilter.changeset(filter)
        |> Ecto.Changeset.apply_changes()
        |> filter_to_params()

      {:noreply,
       socket
       |> push_patch(
         to:
           Routes.report_index_path(
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
  def handle_event("filter", %{"report_filter" => filter}, socket) do
    changeset =
      %ReportFilter{}
      |> ReportFilter.changeset(filter)

    if changeset.valid? do
      params =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> filter_to_params()

      {:noreply,
       socket
       |> push_patch(
         to:
           Routes.report_index_path(
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
              list_reports(socket, page).entries
      }
    )
  end

  defp list_reports(socket, page \\ 1) do
    Reports.list_reports(
      socket.assigns.current_user,
      Ecto.Changeset.apply_changes(socket.assigns.filter),
      page: page,
      page_size: 15
    )
  end

  defp filter_from_params(params) do
    query = params["q"]

    %ReportFilter{}
    |> ReportFilter.changeset(
      Enum.into(params, %{
        "query" => query
      })
    )
    |> Ecto.Changeset.apply_changes()
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp filter_to_params(%ReportFilter{} = filter) do
    params = []

    params =
      if filter.query && filter.query != "" do
        Keyword.put(params, :q, filter.query)
      else
        params
      end

    params =
      if filter.reporter && filter.reporter != "" do
        Keyword.put(params, :reporter, filter.reporter)
      else
        params
      end

    params =
      if filter.investigator && filter.investigator != "" do
        Keyword.put(params, :investigator, filter.investigator)
      else
        params
      end

    params =
      if filter.order_by && filter.order_by != "" && filter.order_by != :default do
        Keyword.put(params, :order_by, filter.order_by)
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
    <Layout flashes={@flash} context={:admin}>
      <h1 class="text-3xl">Reports</h1>
      <div class="divider" />
      <div class="flex flex-col pt-4">
        <Form
          for={@filter}
          change="change"
          submit="filter"
          class="form-control px-4 mx-auto max-w-3xl pb-6 w-full md:w-content"
        >
          <Field class="w-full input-group grow" name={:query}>
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
            <TextInput name={:reporter} />
            <TextInput name={:investigator} />
            <MultipleSelect name={:statuses} options={@status_options} />
            <Select
              name={:order_by}
              class="select select-bordered shrink"
              options={
                "Most Recent": :newest,
                "Least Recent": :oldest,
                Default: :default
              }
            />
            <div class="grid grid-cols-3 gap-2 pt-2">
              <Submit label="Apply" class="btn btn-square btn-primary col-span-2 w-full" />
              <button type="button" :on-click="reset" class="btn-btn-square btn-link w-full">Reset</button>
            </div>
          </Collapse>
        </Form>
        <div class="overflow-x-auto">
          <table class="table border table-zebra border-base-content border-opacity-10 rounded w-full">
            <thead>
              <tr>
                <th />
                <th>Status</th>
                <th>Reporter</th>
                <th>Investigator</th>
                <th>Summary</th>
              </tr>
            </thead>
            {#for report <- @results}
              <tr>
                <td>
                  <LiveRedirect class="btn btn-link" to={Routes.report_show_path(Endpoint, :show, report.id)}>
                    View
                  </LiveRedirect>
                </td>
                <td>{report.status}</td>
                <td><Avatar class="w-4" user={report.reporter} /> <UserHandle user={report.reporter} /></td>
                <td>
                  {#if report.investigator}
                    <Avatar class="w-4" user={report.reporter} /> <UserHandle user={report.reporter} />
                  {#else}
                    Nobody
                  {/if}
                </td>
                <td>
                  {#if report.message && String.length(report.message) > 140}
                    {String.slice(report.message, 0, 140)}...
                  {#elseif report.message}
                    {report.message}
                  {/if}
                </td>
              </tr>
            {/for}
          </table>
          <InfiniteScroll id="reports-infinite-scroll" page={@page} load_more="load_more" />
        </div>
      </div>
    </Layout>
    """
  end
end
