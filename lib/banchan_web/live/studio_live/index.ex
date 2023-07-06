defmodule BanchanWeb.StudioLive.Index do
  @moduledoc """
  Generic listing of your own studios, plus the ability to create new ones.
  """
  use BanchanWeb, :live_view

  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Card, InfiniteScroll, Layout, StudioCard}

  @impl true
  def mount(_params, _session, socket) do
    if :artist in socket.assigns.current_user.roles do
      studios =
        Studios.list_studios(
          with_member: socket.assigns.current_user,
          current_user: socket.assigns.current_user,
          include_own_archived?: true,
          page_size: 24,
          order_by: :newest
        )

      {:ok, assign(socket, studios: studios)}
    else
      {:ok,
       socket
       |> put_flash(
         :error,
         "You can't access this page because you don't have the `artist` role."
       )
       |> push_navigate(to: Routes.home_path(Endpoint, :index))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <h1 class="text-3xl">My Studios</h1>
      <div class="divider" />
      <div class="studio-list grid grid-cols-1 sm:gap-2 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4 auto-rows-fr">
        {#for studio <- @studios}
          <StudioCard studio={studio} />
        {/for}
        <LiveRedirect to={Routes.studio_new_path(Endpoint, :new)}>
          <Card class="border-2 border-dashed shadow-xs opacity-50 hover:opacity-100 hover:bg-base-200 h-full transition-all">
            <div class="m-auto flex flex-col items-center">
              <span class="text-3xl m-auto">New Studio</span>
              <span class="text-sm p-2">Commissions are done through studios, rather than user accounts.</span>
            </div>
          </Card>
        </LiveRedirect>
      </div>
      <InfiniteScroll id="studios-infinite-scroll" page={@studios.page_number} load_more="load_more" />
    </Layout>
    """
  end
end
