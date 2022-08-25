defmodule BanchanWeb.BetaLive.Manage do
  @moduledoc """
  LiveView for managing beta invites.
  """
  use BanchanWeb, :surface_view

  alias Banchan.Accounts
  alias Banchan.Accounts.InviteRequest

  alias Surface.Components.Form
  alias Surface.Components.Form.{NumberInput, Submit}

  alias BanchanWeb.Components.{Avatar, Button, InfiniteScroll, Layout, UserHandle}
  alias BanchanWeb.Components.Form.Checkbox

  @impl true
  def handle_params(_params, uri, socket) do
    socket = socket |> assign(uri: uri, show_sent: false, page: 1)
    {:noreply, socket |> assign(results: list_requests(socket))}
  end

  @impl true
  def handle_event("submit_invites", val, socket) do
    IO.inspect(val)
    {:noreply, socket}
  end

  def handle_event("change_show_sent", %{"show_sent" => %{"show_sent" => show_sent}}, socket) do
    socket = socket |> assign(show_sent: show_sent == "true")
    {:noreply, socket |> assign(results: list_requests(socket))}
  end

  @impl true
  def handle_event("send_invite", req_id, socket) do
    {req_id, ""} = Integer.parse(req_id)
    %InviteRequest{} = req = Accounts.get_invite_request(req_id)

    case Accounts.send_invite(
           socket.assigns.current_user,
           req,
           &Routes.artist_token_url(Endpoint, :confirm_artist, &1)
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Invite sent to #{req.email}")
         |> redirect(to: Routes.beta_manage_path(Endpoint, :index))}

      {:error, err} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unexpected error while inviting #{req.email}: #{err}")
         |> redirect(to: Routes.beta_manage_path(Endpoint, :index))}
    end

    {:noreply, socket}
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
              list_requests(socket, page).entries
      }
    )
  end

  defp list_requests(socket, page \\ 1) do
    Accounts.list_invite_requests(
      unsent_only: !socket.assigns.show_sent,
      page: page,
      page_size: 24
    )
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <h1 class="text-3xl">Manage Invite Requests</h1>
      <div class="divider" />
      <div class="flex flex-col md:flex-row md:flex-wrap">
        <Form class="grow" for={:send_invites} submit="submit_invites">
          <div class="input-group">
            <NumberInput class="input input-bordered" name={:count} opts={placeholder: "Invites to send"} />
            <Submit class="btn btn-primary rounded-lg">Send Invites</Submit>
          </div>
        </Form>
        <Form for={:show_sent} change="change_show_sent">
          <Checkbox name={:show_sent} label="Show sent invites" value={@show_sent} />
        </Form>
      </div>
      <div class="divider" />
      <div class="overflow-x-auto">
        <table class="table table-zebra w-full">
          <thead>
            <tr>
              <th />
              <th>Email</th>
              <th>Requested On</th>
              <th>Generated By</th>
              <th>Used By</th>
            </tr>
          </thead>
          {#for req <- @results}
            <tr>
              <td>
                <Button class="btn-sm" click="send_invite" value={req.id}>Send Invite</Button>
              </td>
              <td>{req.email}</td>
              <td>
                <div title={req.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>
                  {req.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}
                </div>
              </td>
              <td>
                {#if req.token && req.token.generated_by}
                  <div class="flex flex-row items-center gap-2">
                    <Avatar class="w-4" user={req.token.generated_by} /> <UserHandle user={req.token.generated_by} />
                  </div>
                {#else}
                  <span>-</span>
                {/if}
              </td>
              <td>
                {#if req.token && req.token.used_by}
                  <div class="flex flex-row items-center gap-2">
                    <Avatar class="w-4" user={req.token.used_by} /> <UserHandle user={req.token.used_by} />
                  </div>
                {#else}
                  <span>-</span>
                {/if}
              </td>
            </tr>
          {/for}
        </table>
        <InfiniteScroll id="requests-infinite-scroll" page={@page} load_more="load_more" />
      </div>
    </Layout>
    """
  end
end
