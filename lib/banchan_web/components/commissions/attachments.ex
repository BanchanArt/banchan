defmodule BanchanWeb.Components.Commissions.Attachments do
  @moduledoc """
  Box for displaying a preview of all attachments in a commission, on the Commission page.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Endpoint

  def render(assigns) do
    ~F"""
    <div class="card block sidebar-box">
      <header class="card-header">
        <p class="card-header-title">Attachments</p>
      </header>
      <div class="card-content level">
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
      <footer class="card-footer">
        <a class="card-footer-item button is-link" href="#">See All</a>
      </footer>
    </div>
    """
  end
end
