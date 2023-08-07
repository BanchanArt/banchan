defmodule BanchanWeb.AuthLive.Components.AuthLayout do
  @moduledoc """
  Layout component for auth-related pages for consistent look & feel.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Layout

  prop flashes, :any, required: true

  slot default

  def render(assigns) do
    ~F"""
    <Layout flashes={@flashes} padding={0}>
      <div class="grid w-full h-full place-items-center">
        <div class="w-full max-w-md p-10 h-fit rounded-xl md:py-10">
          <#slot />
        </div>
      </div>
    </Layout>
    """
  end
end
