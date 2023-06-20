defmodule BanchanWeb.StaticLive.Membership do
  @moduledoc """
  Banchan Membership Page
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <#Markdown class="prose">
        # Joining Banchan

        We're still working on our membership system. Come back soon.
      </#Markdown>
    </Layout>
    """
  end
end
