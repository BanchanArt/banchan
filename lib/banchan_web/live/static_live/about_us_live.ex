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

        Banchan Art is a website focused on providing a user-friendly space for artists for managing their clients, commissions, and invoices, and for patrons to discover new and existing artists to follow and to commission art.

        ## Our Mission

        Our mission is to become a [Platform Co-operative](https://en.wikipedia.org/wiki/Platform_cooperative)
        of workers and artists coming together to create a new kind of art community. You can read more about that on our [membership page](/membership).

        The platform co-operative model provides an alternative to the typical media sites that are often funded by
        [venture capitalists](https://en.wikipedia.org/wiki/Venture_capital), which are built
        to extract value from artists and their work, at their expense, while doing their best
        to crush any alternative they might otherwise have.

        This platform is created, owned, and maintained with love and solidarity by Banchan Art LLC. We work in solidarity with organizations like [Artisans.Coop](https://artisans.coop/),
        [Comradery](https://comradery.co/), and [Ampled](https://www.ampled.com/) to imagine
        a different economy for the future.

        ## Behind the Name

        Banchan Art is named for the Korean culinary tradition of shared side dishes known as [banchan](https://en.wikipedia.org/wiki/Banchan).

        Banchan includes a variety of dishes with different flavors and meanings. Each meal is a unique experience due to the constantly rotating selection of dishes and your ability to cater your meal by how much of each dish you select for yourself. You are able to satiate your palate for different tastes as you please.

        The idea behind Banchan Art is to build a platform that provides a meeting point for artists and their supporters. This is a place where both artists and their patrons can customize their experience in a mutually beneficial and harmonious way. Our ideal for the platform is to make it easy and enjoyable to commission a custom piece of art for both sides. Similar to choosing different amounts of banchan to cater a meal to your taste, supporters can choose from different options set up by artists to commission the art piece that they will treasure.

      </#Markdown>
    </Layout>
    """
  end
end
