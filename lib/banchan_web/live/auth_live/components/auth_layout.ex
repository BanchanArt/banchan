defmodule BanchanWeb.AuthLive.Components.AuthLayout do
  @moduledoc """
  Layout component for auth-related pages for consistent look & feel.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Layout

  prop uri, :string, required: true
  prop current_user, :any, required: true
  prop flashes, :any, required: true

  slot default

  def render(assigns) do
    ~F"""
    <Layout uri={@uri} padding="0" current_user={@current_user} flashes={@flashes}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-sm w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <#slot />
        </div>
      </div>
    </Layout>
    """
  end
end
