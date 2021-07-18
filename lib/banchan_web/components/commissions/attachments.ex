defmodule BanchanWeb.Components.Commissions.Attachments do
  @moduledoc """
  Box for displaying a preview of all attachments in a commission, on the Commission page.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        Attachments
      </:header>
      <div class="level">
        <div class="level-left">
          <figure class="image is-96x96">
            <img src={Routes.static_path(Endpoint, "/images/penana-left.png")}>
          </figure>
          <figure class="image is-96x96">
            <img src={Routes.static_path(Endpoint, "/images/penana-right.png")}>
          </figure>
          <figure class="image is-96x96">
            <img src={Routes.static_path(Endpoint, "/images/penana-front.png")}>
          </figure>
        </div>
      </div>
      <:footer>
        <a class="card-footer-item button is-link" href="#">See All</a>
      </:footer>
    </Card>
    """
  end
end
