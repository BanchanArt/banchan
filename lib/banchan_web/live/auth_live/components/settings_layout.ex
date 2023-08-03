defmodule BanchanWeb.AuthLive.Components.SettingsLayout do
  @moduledoc """
  Layout component for settings-related pages for consistent look & feel.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Layout

  prop flashes, :any, required: true

  slot default

  def render(assigns) do
    ~F"""
    <Layout flashes={@flashes} padding={0}>
      <div class="flex flex-row items-center justify-center w-full">
        <div class="max-w-5xl p-12 rounded-xl md:my-12 md:mx-12 bg-base-100">
          <#slot />
        </div>
      </div>
    </Layout>
    """
  end
end
