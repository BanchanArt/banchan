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
      {#if slot_assigned?(:header)}
        <header class="card-header">
          <p class="card-header-title">
            <#slot name="header" />
          </p>
        </header>
      {/if}
      <div class="card-content">
        <#slot />
      </div>
      {#if slot_assigned?(:footer)}
        <footer class="card-footer">
          <#slot name="footer" />
        </footer>
      {/if}
    </div>
    """
  end
end
