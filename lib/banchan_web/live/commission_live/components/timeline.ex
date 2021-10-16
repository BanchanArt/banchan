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
      <article class="timeline-item">
        <Card>
          <:header>
            <img class="w-6" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
            {@current_user.handle} commented 3 days ago.
          </:header>

          <div class="content">
            Hello I would like a really nice commission of my cool OC. I've attached some screenshots.
          </div>

          <:footer>
          <img class="inline w-16" src={Routes.static_path(Endpoint, "/images/penana-left.png")}>
          <img class="inline w-16" src={Routes.static_path(Endpoint, "/images/penana-right.png")}>
          <img class="inline w-16" src={Routes.static_path(Endpoint, "/images/penana-front.png")}>
          </:footer>
        </Card>
      </article>

      <p class="timeline-item block"><i class="fas fa-clipboard-check" /> {@current_user.handle} submitted this commission 3 days ago.</p>

      <article class="timeline-item block">
        <Card>
          <:header>
            <img class="w-6" src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
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

      <article class="timeline-item">
        <Card>
          <:header>
            <img class="w-6" src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
            skullbunnygalaxy commented 2 days ago.
          </:header>

          <div class="content">
            Hey can you tell me more about this character? What's their favorite food?
          </div>
        </Card>
      </article>

      <p class="timeline-item"><small><i class="fas fa-hourglass-half" /> skullbunnygalaxy changed the status to Waiting for Customer.</small></p>
    </div>
    """
  end
end
