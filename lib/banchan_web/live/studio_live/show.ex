defmodule BanchanWeb.StudioLive.Show do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.{Card, Layout}
  alias BanchanWeb.StudioLive.Components.{CommissionCard}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket, false)
    studio = Studios.get_studio_by_slug!(slug)
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
        <section class="hero is-primary">
          <div class="hero-body">
            <p class="title">
              {@studio.name}
            </p>
            <p class="subtitle">
              {@studio.description}
              {#if @current_user_member?}
                <LiveRedirect
                  class="button is-light is-small"
                  label="Edit Profile"
                  to={Routes.studio_edit_path(Endpoint, :edit, @studio.slug)}
                />
              {/if}
            </p>
          </div>
          <div class="hero-foot">
            <nav class="tabs is-boxed">
              <div class="container">
                <ul>
                  <li class="is-active">
                    <a>Shop</a>
                  </li>
                  <li>
                    <a>About</a>
                  </li>
                  <li>
                    <a>Portfolio</a>
                  </li>
                  <li>
                    <a>Q&A</a>
                  </li>
                </ul>
              </div>
            </nav>
          </div>
        </section>
      </:hero>
      <div class="studio columns">
        <div class="column is-two-thirds">
          <div class="offerings columns is-multiline">
            {#for offering <- @offerings}
              <div class="column">
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
              <div class="column">
                <button type="button" class="button is-light">Add a Tier</button>
              </div>
            {/if}
          </div>
        </div>
    
        <div class="column">
          <div class="block">
            <Card>
              <:header>
                Summary
              </:header>
              <div class="content">
                <h3>These are all private commissions, meaning: <strong>non-commercial</strong></h3>
                <p>You're only paying for my service to create the work not copyrights or licensing of the work itself!</p>
                <h3>I will draw</h3>
                <ul>
                  <li>Humans/humanoids</li>
                  <li>anthros+furries/creatures/monsters/animals</li>
                  <li>mecha/robots/vehicles</li>
                  <li>environments/any type of background</li>
                </ul>
                <h3>I will not draw</h3>
                <ul>
                  <li>NSFW</li>
                  <li>Fanart</li>
                </ul>
              </div>
            </Card>
          </div>
    
          <div class="block">
            <h2 class="subtitle">Members</h2>
            <div class="studio-members columns is-multiline">
              {#for member <- @members}
                <div class="column">
                  <figure class="column image is-64x64">
                    <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, member.handle)}>
                      <img
                        alt={member.name}
                        class="is-rounded"
                        src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
                      />
                    </LiveRedirect>
                  </figure>
                </div>
              {/for}
            </div>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
