defmodule BanchanWeb.StudioLive.Show do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.LiveRedirect

  alias Banchan.Studios
  alias BanchanWeb.Components.{Card, Layout}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"slug" => slug}, session, socket) do
    socket = assign_defaults(session, socket, false)
    studio = Studios.get_studio_by_slug!(slug)
    members = Studios.list_studio_members(studio)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio(socket.assigns.current_user, studio)

    {:ok,
     assign(socket, studio: studio, members: members, current_user_member?: current_user_member?)}
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
            <div class="column">
              <Card>
                <:header>
                  Illustration
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-danger is-light">5/5 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/hj-illustration.jpg")}>
                  </figure>
                </:image>
                <div class="content">
                  <p>A waist-up illustration of your character with background of choice!</p>
                  <p>$500-$1000</p>
                </div>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Details</a>
                </:footer>
              </Card>
            </div>

            <div class="column">
              <Card>
                <:header>
                  Character
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-success is-light">2/5 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/hj-character.jpg")}>
                  </figure>
                </:image>
                <div class="content">
                  <p>A clean full-body illustration of your character with NO background!</p>
                  <p>$225-$500+</p>
                </div>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Details</a>
                </:footer>
              </Card>
            </div>

            <div class="column">
              <Card>
                <:header>
                  Character Page
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-warning is-light">2/3 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/hj-character-page.jpg")}>
                  </figure>
                </:image>
                <div class="content">
                  <p>A page spread depicting your character in a variety of illustrations collaged together!</p>
                  <p>$225-$600+</p>
                </div>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Details</a>
                </:footer>
              </Card>
            </div>

            <div class="column">
              <Card>
                <:header>
                  Chibi Icon
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-success is-light">3/10 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/hj-chibi-icon.png")}>
                  </figure>
                </:image>
                <p>A rendered bust of your character in a chibi/miniaturized style! Square composition for icon use.</p>
                <p>$100-$200</p>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Details</a>
                </:footer>
              </Card>
            </div>

            <div class="column">
              <Card>
                <:header>
                  Character Bust
                </:header>
                <:header_aside>
                  <span class="tag is-medium is-danger is-light">5/5 slots</span>
                </:header_aside>
                <:image>
                  <figure class="image is-16by9">
                    <img src={Routes.static_path(Endpoint, "/images/hj-bust.jpg")}>
                  </figure>
                </:image>
                <p>A clean bust illustration of your character with NO background!</p>
                <p>$75-$150</p>
                <:footer>
                  <a class="button is-primary card-footer-item" href="#">Details</a>
                </:footer>
              </Card>
            </div>

            <div class="column">
              <button type="button" class="button is-light">Add a Tier</button>
            </div>
          </div>
        </div>

        <div class="column">
          <div class="block">
            <Card>
              <:header>
                Summary
              </:header>
              <:header_aside>
                <button type="button" class="button is-light is-small">Edit</button>
              </:header_aside>
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
