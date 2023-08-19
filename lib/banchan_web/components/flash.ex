defmodule BanchanWeb.Components.Flash do
  @moduledoc """
  Handles displaying flashes for a page.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  prop flashes, :any, required: true

  def render(assigns) do
    ~F"""
    <div class="fixed bottom-auto z-20 w-full p-0 mx-auto translate-y-0 flash-container md:max-w-sm lg:max-w-md xl:max-w-lg 2xl:max-w-xl toast toast-center top-20">
      {#if live_flash(@flashes, :success)}
        <div
          class="px-4 py-2 rounded-lg alert alert-success hover:cursor-pointer"
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
          class="px-4 py-2 rounded-lg alert alert-info hover:cursor-pointer"
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
          class="px-4 py-2 rounded-lg alert alert-warning hover:cursor-pointer"
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
          class="px-4 py-2 rounded-lg alert alert-error hover:cursor-pointer"
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
