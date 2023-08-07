defmodule BanchanWeb.StudioLive.Components.Blocklist do
  @moduledoc """
  Displaying and managing a studio's blocklist.
  """
  use BanchanWeb, :live_component

  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Studios

  alias BanchanWeb.Components.{Avatar, UserHandle}

  prop studio, :struct, required: true

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket |> assign(studio: socket.assigns.studio |> Repo.preload(blocklist: [:user]))}
  end

  @impl true
  def handle_event("unblock", %{"user" => uid}, socket) do
    {uid, ""} = Integer.parse(uid)

    Studios.unblock_user(socket.assigns.current_user, socket.assigns.studio, %User{id: uid})

    new_blocklist =
      socket.assigns.studio.blocklist
      |> Enum.filter(&(&1.user_id != uid))

    {:noreply,
     socket
     |> assign(studio: %{socket.assigns.studio | blocklist: new_blocklist})}
  end

  def render(assigns) do
    ~F"""
    <table class="table w-full border rounded table-zebra border-base-content border-opacity-10">
      <thead>
        <tr>
          <th>User</th>
          <th>Reason</th>
        </tr>
      </thead>
      {#for block <- @studio.blocklist}
        <tr>
          <td class="flex flex-row items-center gap-2">
            <button
              type="button"
              :on-click="unblock"
              phx-value-user={block.user_id}
              class="btn btn-circle btn-sm"
            >✕</button>
            <Avatar class="w-12" user={block.user} /> <UserHandle user={block.user} />
          </td>
          <td>
            {block.reason}
          </td>
        </tr>
      {/for}
    </table>
    """
  end
end
