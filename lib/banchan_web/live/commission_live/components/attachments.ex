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
      <img class="inline w-16" src={Routes.static_path(Endpoint, "/images/penana-left.png")}> <img class="inline w-16" src={Routes.static_path(Endpoint, "/images/penana-right.png")}> <img class="inline w-16" src={Routes.static_path(Endpoint, "/images/penana-front.png")}> <:footer>
        <a href="#">See All</a>
      </:footer>
    </Card>
    """
  end
end
