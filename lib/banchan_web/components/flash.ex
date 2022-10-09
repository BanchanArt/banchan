defmodule BanchanWeb.Components.Flash do
  @moduledoc """
  Handles displaying flashes for a page.
  """
  use BanchanWeb, :component

  prop flash, :any, from_context: :flash

  def render(assigns) do
    ~F"""
    <div class="flash-container">
      {#if live_flash(@flash, :success)}
        <div
          class="alert alert-success shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "success"}
        >
          <div>
            <i class="fas fa-check-circle" />
            <span>{live_flash(@flash, :success)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flash, :info)}
        <div
          class="alert alert-info shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "info"}
        >
          <div>
            <i class="fas fa-info-circle" />
            <span>{live_flash(@flash, :info)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flash, :warning)}
        <div
          class="alert alert-warning shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "warning"}
        >
          <div>
            <i class="fas fa-exclamation-triangle" />
            <span>{live_flash(@flash, :warning)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flash, :error)}
        <div
          class="alert alert-error shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "error"}
        >
          <div>
            <i class="fas fa-exclamation-circle" />
            <span>{live_flash(@flash, :error)}</span>
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
