defmodule BanchanWeb.DenizenLive.Index do
  @moduledoc """
  Global listing of users.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts
  alias Banchan.Accounts.UserFilter

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Submit}
  alias Surface.Components.Form.TextInput, as: SurfaceTextInput

  alias BanchanWeb.Components.{Avatar, InfiniteScroll, Layout, UserHandle}

  @impl true
  def handle_params(params, uri, socket) do
    socket =
      socket
      |> assign(
        :filter,
        UserFilter.changeset(filter_from_params(params))
      )

    socket =
      socket
      |> assign(
        query: params[:query],
        page: 1
      )

    socket = socket |> assign(results: list_users(socket))

    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("load_more", _, socket) do
    if socket.assigns.results.total_entries >
         socket.assigns.page * socket.assigns.results.page_size do
      {:noreply, socket |> assign(page: socket.assigns.page + 1) |> fetch()}
    else
      {:noreply, socket}
    end
  end

  def handle_event("submit", %{"user_filter" => filter}, socket) do
    changeset =
      %UserFilter{}
      |> UserFilter.changeset(filter)

    if changeset.valid? do
      params =
        changeset
        |> Ecto.Changeset.apply_changes()
        |> filter_to_params()

      {:noreply,
       socket
       |> push_patch(
         to:
           Routes.denizen_index_path(
             Endpoint,
             :index,
             params
           )
       )}
    else
      {:noreply, assign(socket, filter: changeset)}
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
              list_users(socket, page).entries
      }
    )
  end

  defp filter_from_params(params) do
    query = params["q"]

    %UserFilter{}
    |> UserFilter.changeset(
      Enum.into(params, %{
        "query" => query
      })
    )
    |> Ecto.Changeset.apply_changes()
  end

  defp filter_to_params(%UserFilter{} = filter) do
    params = []

    params =
      if filter.query && filter.query != "" do
        Keyword.put(params, :q, filter.query)
      else
        params
      end

    params
  end

  defp list_users(socket, page \\ 1) do
    Accounts.list_users(
      socket.assigns.current_user,
      Ecto.Changeset.apply_changes(socket.assigns.filter),
      page: page,
      page_size: 15
    )
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <h1 class="text-3xl">Users</h1>
      <div class="divider" />
      <div class="flex flex-col pt-4">
        <Form
          for={@filter}
          submit="submit"
          class="form-control px-4 mx-auto max-w-3xl pb-6 w-full md:w-content"
        >
          <Field class="w-full input-group grow" name={:query}>
            <SurfaceTextInput class="input input-bordered w-full" />
            <Submit class="btn btn-square">
              <i class="fas fa-search" />
            </Submit>
          </Field>
        </Form>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>User</th>
                <th>Display Name</th>
                <th>Signed Up On</th>
              </tr>
            </thead>
            {#for user <- @results}
              <tr>
                <td class="flex flex-row items-center gap-2"><Avatar class="w-4" user={user} /> <UserHandle user={user} /></td>
                <td>{user.name}</td>
                <td>
                  {user.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}
                </td>
              </tr>
            {/for}
          </table>
          <InfiniteScroll id="users-infinite-scroll" page={@page} load_more="load_more" />
        </div>
      </div>
    </Layout>
    """
  end
end
