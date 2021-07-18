defmodule BanchanWeb.Components.Card do
  @moduledoc """
  Generic (Bulma) card component.
  """
  use BanchanWeb, :component

  @doc "The header"
  slot header

  @doc "The footer"
  slot footer

  @doc "The main content"
  slot default, required: true

  def render(assigns) do
    ~F"""
    <div class="card">
      <header class="card-header">
        <p class="card-header-title">
          <#slot name="header" />
        </p>
      </header>
      <div class="card-content">
        <#slot />
      </div>
      <footer class="card-footer">
        <#slot name="footer" />
      </footer>
    </div>
    """
  end
end
