defmodule BanchanWeb.Components.Commissions.Timeline do
  @moduledoc """
  Main component for the Commission Page's timeline.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  prop current_user, :any, required: true
  prop commission, :any, required: true

  def render(assigns) do
    ~F"""
    <div class="timeline">
      <article class="timeline-item block">
        <Card>
          <:header>
            <figure class="image is-24x24">
              <img class="is-rounded" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
            </figure>
            {@current_user.handle} commented 3 days ago.
          </:header>

          <div class="content">
            Hello I would like a really nice commission of my cool OC. I've attached some screenshots.
          </div>

          <:footer>
            <div class="card-footer-item level">
              <div class="level-left">
                <figure class="image block is-96x96">
                  <img src={Routes.static_path(Endpoint, "/images/penana-left.png")}>
                </figure>
                <figure class="image block is-96x96">
                  <img src={Routes.static_path(Endpoint, "/images/penana-right.png")}>
                </figure>
                <figure class="image block is-96x96">
                  <img src={Routes.static_path(Endpoint, "/images/penana-front.png")}>
                </figure>
              </div>
            </div>
          </:footer>
        </Card>
      </article>

      <p class="timeline-item block"><i class="fas fa-clipboard-check" /> {@current_user.handle} submitted this commission 3 days ago.</p>

      <article class="timeline-item block">
        <Card>
          <:header>
            <figure class="image is-24x24">
              <img class="is-rounded" src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
            </figure>
            skullbunnygalaxy commented 2 days ago.
          </:header>

          <div class="content">
            <p>Hi, I'm happy to work on this! It sounds really cute.</p>
            <p>I can get started as soon as I receive the initial payment!</p>
          </div>
        </Card>
      </article>

      <p class="timeline-item block"><i class="fas fa-clipboard-check" /> skullbunnygalaxy accepted this commission 2 days ago.</p>

      <p class="timeline-item block"><i class="fas fa-file-invoice-dollar" /> skullbunnygalaxy requested <span class="tag is-warning">$100.25</span></p>

      <p class="timeline-item block"><i class="fas fa-donate" /> {@current_user.handle} paid <span class="tag is-success">$100.25</span></p>

      <p class="timeline-item block"><i class="fas fa-palette" /> skullbunnygalaxy started working on this commission.</p>

      <article class="timeline-item block">
        <Card>
          <figure class="image is-24x24">
            <img class="is-rounded" src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
          </figure>
          skullbunnygalaxy commented 2 days ago.

          <div class="content">
            Hey can you tell me more about this character? What's their favorite food?
          </div>
        </Card>
      </article>

      <p class="timeline-item block"><small><i class="fas fa-hourglass-half" /> skullbunnygalaxy changed the status to Waiting for Customer.</small></p>
    </div>
    """
  end
end
