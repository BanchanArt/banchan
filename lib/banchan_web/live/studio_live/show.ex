defmodule BanchanWeb.StudioLive.Show do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.TabButton
  alias BanchanWeb.StudioLive.Tabs

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket, false)
    studio = Studios.get_studio_by_handle!(handle)
    members = Studios.list_studio_members(studio)
    offerings = Studios.list_studio_offerings(studio)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio(socket.assigns.current_user, studio)

    {:ok,
     assign(socket,
       studio: studio,
       members: members,
       offerings: offerings,
       current_user_member?: current_user_member?
     )}
  end

  @impl true
  def handle_params(_, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <:hero>
        <section class="grid grid-cols-2 bg-secondary">
          <div class="ml-8 col-span-12">
            <p class="text-3xl text-secondary-content font-bold flex-grow">
              {@studio.name}
            </p>
            <p class="text-base text-secondary-content flex-grow">
              {@studio.description}
              {#if @current_user_member?}
                <LiveRedirect
                  class="btn glass btn-sm text-center rounded-full px-2 py-0"
                  label="Edit Profile"
                  to={Routes.studio_edit_path(Endpoint, :edit, @studio.handle)}
                />
              {#else}
                {!-- TODO: add in follow functionality --}
                <a
                  href="/"
                  class="btn glass btn-sm text-center rounded-full px-2 py-0"
                  label="Follow"
                >Follow</a>
              {/if}
            </p>
            <br>
          </div>
          <nav class="tabs ml-8 col-span-1 grid-cols-4 inline-grid">
            <TabButton studio={@studio} label="Shop" tab={:shop} live_action={@live_action} />
            <TabButton studio={@studio} label="About" tab={:about} live_action={@live_action} />
            <TabButton studio={@studio} label="Portfolio" tab={:portfolio} live_action={@live_action} />
            <TabButton studio={@studio} label="Q&A" tab={:qa} live_action={@live_action} />
          </nav>
        </section>
      </:hero>
      <div class="grid grid-cols-3 justify-items-stretch gap-6">
      {#case @live_action}
        {#match :shop}
          <Tabs.Shop
            studio={@studio}
            members={@members}
            offerings={@offerings}
            current_user_member?={@current_user_member?}
          />
        {#match :about}
          About Tab
        {#match :portfolio}
          Portfolio Tab
        {#match :qa}
          Q&A Tab
      {/case}
      </div>
    </Layout>
    """
  end
end
