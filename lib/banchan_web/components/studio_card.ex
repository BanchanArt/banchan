defmodule BanchanWeb.Components.StudioCard do
  @moduledoc """
  Card for displaying studio information
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Endpoint

  prop studio, :any

  def render(assigns) do
    ~F"""
    <li class="studio-card">
      <LiveRedirect label={@studio.name} to={Routes.studio_show_path(Endpoint, :show, @studio.slug)} />
    </li>
    """
  end
end
