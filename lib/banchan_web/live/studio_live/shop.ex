defmodule BanchanWeb.StudioLive.Shop do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.{CommissionCard, StudioLayout}
  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(session, socket, false)
    socket = assign_studio_defaults(params, socket, false)
    studio = socket.assigns.studio
    members = Studios.list_studio_members(studio)
    offerings = Studios.list_studio_offerings(studio)

    {:ok, assign(socket, members: members, offerings: offerings)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:shop}
    >
      <div class="grid grid-cols-3 justify-items-stretch gap-6">
        <div class="offerings">
          {#for offering <- @offerings}
            <div class="shadow-lg bg-base-200 card card-bordered">
              <CommissionCard studio={@studio} offering={offering} />
            </div>
          {/for}
          {#if @current_user_member?}
            <div class="">
              <LiveRedirect
                to={Routes.studio_offerings_index_path(Endpoint, :index, @studio.handle)}
                class="btn btn-sm text-center rounded-full m-5 btn-warning"
              >Manage Offerings</LiveRedirect>
            </div>
          {/if}
        </div>
        <div class="col-start-3">
          <div class="shadow-lg bg-base-200 card card-bordered">
            <Card>
              <:header>
                Summary
              </:header>
              <div class="content leading-loose">
                <h3 class="text-2xl mt-4">These are all private commissions, meaning: <strong>non-commercial</strong></h3>
                <p class="mt-4">You're only paying for my service to create the work not copyrights or licensing of the work itself!</p>
                <h3 class="text-xl mt-4">I will draw</h3>
                <ul class="list-disc list-inside">
                  <li>Humans/humanoids</li>
                  <li>anthros+furries/creatures/monsters/animals</li>
                  <li>mecha/robots/vehicles</li>
                  <li>environments/any type of background</li>
                </ul>
                <h3 class="text-xl mt-4">I will not draw</h3>
                <ul class="list-disc list-inside">
                  <li>NSFW</li>
                  <li>Fanart</li>
                </ul>
              </div>
            </Card>
          </div>
          <div class="shadow-lg bg-base-200 card card-bordered card-compact">
            <h2 class="text-xl">Members</h2>
            <div class="studio-members grid grid-cols-4 gap-1">
              {#for member <- @members}
                <figure class="col-span-1">
                  <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, member.handle)}>
                    <img
                      alt={member.name}
                      class="rounded-full h-24 w-24 flex items-center justify-center"
                      src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
                    />
                  </LiveRedirect>
                </figure>
              {/for}
            </div>
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
