defmodule BanchanWeb.StaticLive.AboutUs do
  @moduledoc """
  Banchan About Us Page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def handle_params(_params, uri, socket) do
    socket = Context.put(socket, uri: uri)
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <#Markdown class="prose">
        # About Banchan Art

        We are a [Platform Co-operative](https://en.wikipedia.org/wiki/Platform_cooperative)
        of workers and artists coming together to create a new art community where artists
        can grow and do their work safely.
      </#Markdown>
    </Layout>
    """
  end
end
