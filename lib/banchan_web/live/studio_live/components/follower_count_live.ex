defmodule BanchanWeb.StudioLive.Components.FollowerCountLive do
  @moduledoc """
  Follower count LiveView. It's a LiveView because components can't receive
  PubSub messages.
  """
  use BanchanWeb, :live_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios

  def mount(_params, %{"handle" => handle}, socket) do
    studio = Studios.get_studio_by_handle!(handle)
    Studios.Notifications.subscribe_to_follower_count(studio)

    {:ok,
     socket
     |> assign(studio: studio, follower_count: Studios.Notifications.follower_count(studio))}
  end

  def handle_info(%{event: "follower_count_changed", payload: new_count}, socket) do
    {:noreply, socket |> assign(follower_count: new_count)}
  end

  def render(assigns) do
    ~F"""
    <LiveRedirect
      class="hover:link"
      to={Routes.studio_followers_path(Endpoint, :index, @studio.handle)}
    >
      {#if @follower_count > 9999}
        <span class="font-bold">{Number.SI.number_to_si(@follower_count)}</span>
      {#else}
        <span class="font-bold">
          {Number.Delimit.number_to_delimited(@follower_count, precision: 0)}
        </span>
      {/if}
      <span>
        {#if @follower_count == 1}
          Follower
        {#else}
          Followers
        {/if}
      </span>
    </LiveRedirect>
    """
  end
end
