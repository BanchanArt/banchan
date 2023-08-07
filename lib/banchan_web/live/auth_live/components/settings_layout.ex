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
      <div class="w-full bg-base-200">
        <div class="w-full max-w-5xl p-10 mx-auto">
          <#slot />
        </div>
      </div>
    </Layout>
    """
  end
end
