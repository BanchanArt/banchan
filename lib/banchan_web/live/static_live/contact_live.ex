defmodule BanchanWeb.StaticLive.Contact do
  @moduledoc """
  Banchan Contact Page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Markdown

  alias BanchanWeb.Components.Layout

  @impl true
  def handle_params(_params, uri, socket) do
    socket = Context.put(socket, uri: uri, flash: socket.assigns.flash)
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <#Markdown class="prose">
        # Contact Us

        Feel free to email us at [support@banchan.art](mailto:support@banchan.art).
      </#Markdown>
    </Layout>
    """
  end
end
