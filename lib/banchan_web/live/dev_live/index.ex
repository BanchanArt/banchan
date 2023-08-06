defmodule BanchanWeb.DevLive.Index do
  @moduledoc """
  Landing page for Dev context.
  """
  use BanchanWeb, :live_view

  alias BanchanWeb.Components.Layout

  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} context={:dev}>
      Nothing to see here yet. Check nav for stuff to look at.
    </Layout>
    """
  end
end
