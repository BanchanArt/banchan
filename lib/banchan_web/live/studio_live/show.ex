defmodule BanchanWeb.StudioLive.Show do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.{Card, Layout}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.CommissionCard

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
                <a
                  href="/"
                  #TODO:
                  add
                  in
                  follow
                  functionality
                  class="btn glass btn-sm text-center rounded-full px-2 py-0"
                  label="Follow"
                >Follow</a>
              {/if}
            </p>
            <br>
          </div>
          <nav class="tabs ml-8 col-span-1 grid-cols-4 inline-grid">
            <div class="tab tab-bordered tab-active bg-primary-focus text-center rounded-t-lg text-secondary-content"><a>Shop</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>About</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Portfolio</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Q&A</a></div>
          </nav>
        </section>
      </:hero>
      <div class="grid grid-cols-3 justify-items-stretch gap-6">
        <div class="offerings">
          {#for offering <- @offerings}
            <div class="shadow-lg bg-base-200 p-2 my-4 rounded">
              {!-- TODO: Add image --}
              <CommissionCard
                studio={@studio}
                type_id={offering.type}
                name={offering.name}
                description={offering.description}
                image={Routes.static_path(Endpoint, "/images/640x360.png")}
                open={offering.open}
                price_range={offering.price_range}
              />
            </div>
          {/for}
          {#if @current_user_member?}
            <div class="">
              <button type="button" class="btn btn-sm text-center rounded-full px-2 py-1 btn-accent">Add an Offering</button>
            </div>
          {/if}
        </div>
        <div class="col-start-3">
          <div class="shadow-lg bg-base-200 p-2 my-4 rounded">
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
          <div class="shadow-lg bg-base-200 p-2 my-4 rounded">
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
    </Layout>
    """
  end
end
