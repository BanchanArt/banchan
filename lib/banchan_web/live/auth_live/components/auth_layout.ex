defmodule BanchanWeb.AuthLive.Components.AuthLayout do
  @moduledoc """
  Layout component for auth-related pages for consistent look & feel.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Layout

  slot default

  def render(assigns) do
    ~F"""
    <Layout padding={0}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-sm w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <#slot />
        </div>
      </div>
    </Layout>
    """
  end
end
