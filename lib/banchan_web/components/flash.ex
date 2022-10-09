defmodule BanchanWeb.Components.Flash do
  @moduledoc """
  Handles displaying flashes for a page.
  """
  use BanchanWeb, :component

  prop flashes, :any, required: true

  def render(assigns) do
    ~F"""
    <div class="flash-container">
      {#if live_flash(@flashes, :success)}
        <div
          class="alert alert-success shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "success"}
        >
          <div>
            <i class="fas fa-check-circle" />
            <span>{live_flash(@flashes, :success)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flashes, :info)}
        <div
          class="alert alert-info shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "info"}
        >
          <div>
            <i class="fas fa-info-circle" />
            <span>{live_flash(@flashes, :info)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flashes, :warning)}
        <div
          class="alert alert-warning shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "warning"}
        >
          <div>
            <i class="fas fa-exclamation-triangle" />
            <span>{live_flash(@flashes, :warning)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flashes, :error)}
        <div
          class="alert alert-error shadow-lg p-2 hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "error"}
        >
          <div>
            <i class="fas fa-exclamation-circle" />
            <span>{live_flash(@flashes, :error)}</span>
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
