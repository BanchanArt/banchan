defmodule BanchanWeb.Components.Commissions.Status do
  @moduledoc """
  Status box with dropdown, for Commissions page.
  """
  use BanchanWeb, :live_component

  def render(assigns) do
    ~F"""
    <div class="card">
      <header class="card-header">
        <p class="card-header-title">Status</p>
      </header>
      <div class="card-content">
        <div class="dropdown is-active">
          <div class="dropdown-trigger">
            <button class="button" aria-haspopup="true" aria-controls="dropdown-menu">
              <span><i class="fas fa-hourglass-half" /> Waiting for Customer</span>
              <span class="icon is-small">
                <i class="fas fa-angle-down" aria-hidden="true" />
              </span>
            </button>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
