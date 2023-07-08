defmodule BanchanWeb.StaticLive.AboutUs do
  @moduledoc """
  Banchan About Us Page
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <#Markdown class="prose">
        # About Banchan Art

        We are a [Platform Co-operative](https://en.wikipedia.org/wiki/Platform_cooperative)
        of workers and artists coming together to create a new kind of art community.

        ## Our Mission

        Our mission is to build an alternative space to the traditional, often funded by
        [venture capitalist](https://en.wikipedia.org/wiki/Venture_capital), which are built
        to extract value from artists and their work, at their expense, while doing their best
        to crush any alternative they might otherwise have.

        We work in solidarity with organizations like [Artisans.Coop](https://artisans.coop/),
        [Comradery](https://comradery.co/), and [Ampled](https://www.ampled.com/) to imagine
        a different economy for the future.

      </#Markdown>
    </Layout>
    """
  end
end
