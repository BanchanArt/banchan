defmodule BanchanWeb.Components.Modal do
  @moduledoc """
  DaisyUI-based modal component
  """
  use BanchanWeb, :live_component

  prop big, :boolean, default: false

  data modal_open, :boolean, default: false

  slot default
  slot title
  slot action

  def show(modal_id) do
    send_update(__MODULE__, id: modal_id, modal_open: true)
  end

  def hide(modal_id) do
    send_update(__MODULE__, id: modal_id, modal_open: false)
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, socket |> assign(modal_open: false)}
  end

  def handle_event("nothing", _, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div>
      <div
        class="modal modal-open"
        :on-click="close_modal"
        :on-window-keydown="close_modal"
        phx-key="Escape"
        :if={@modal_open}
      >
        {!--
             NB(@zkat): This lg:w-8/12 is a crappy hack to prevent weird
             z-index overlapping issues with the drawer. It can be taken out
             if/when we figure out a different drawer situation than DaisyUI's
             built-in one.
          --}
        <div :on-click="nothing" class={"modal-box relative", "sm:w-11/12 sm:max-w-5xl lg:w-8/12": @big}>
          <div class="btn btn-sm btn-circle close-modal absolute right-2 top-2" :on-click="close_modal">✕</div>
          <h3 class="text-lg font-bold">
            <#slot name="title" />
          </h3>
          <p class="py-4">
            <#slot />
          </p>
          <div class="modal-action">
            <#slot name="action" />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
