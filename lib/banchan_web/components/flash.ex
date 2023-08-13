defmodule BanchanWeb.Components.Flash do
  @moduledoc """
  Handles displaying flashes for a page.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  prop flashes, :any, required: true

  def render(assigns) do
    ~F"""
    <div class="flash-container fixed bottom-auto z-20 w-auto max-w-3/5 translate-y-0 toast toast-center top-20">
      {#if live_flash(@flashes, :success)}
        <div
          class="p-2 alert alert-success hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "success"}
        >
          <div>
            <Icon name="check-circle-2" size="4" />
            <span>{live_flash(@flashes, :success)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flashes, :info)}
        <div
          class="p-2 alert alert-info hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "info"}
        >
          <div>
            <Icon name="info" size="4" />
            <span>{live_flash(@flashes, :info)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flashes, :warning)}
        <div
          class="p-2 alert alert-warning hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "warning"}
        >
          <div>
            <Icon name="alert-triangle" size="4" />
            <span>{live_flash(@flashes, :warning)}</span>
          </div>
        </div>
      {/if}

      {#if live_flash(@flashes, :error)}
        <div
          class="p-2 alert alert-error hover:cursor-pointer"
          role="alert"
          :on-click="lv:clear-flash"
          :values={key: "error"}
        >
          <div>
            <Icon name="x-circle" size="4" />
            <span>{live_flash(@flashes, :error)}</span>
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
