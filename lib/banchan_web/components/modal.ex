defmodule BanchanWeb.Components.Modal do
  @moduledoc """
  DaisyUI-based modal component
  """
  use BanchanWeb, :live_component

  prop big, :boolean, default: false
  prop class, :css_class
  prop always_render_body, :boolean, default: false

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
    <div
      class={"modal", @class, "modal-open": @modal_open}
      :on-click="close_modal"
      :on-window-keydown="close_modal"
      phx-key="Escape"
    >
      {!--
             NB(@zkat): This lg:w-8/12 is a crappy hack to prevent weird
             z-index overlapping issues with the drawer. It can be taken out
             if/when we figure out a different drawer situation than DaisyUI's
             built-in one.
          --}
      <div
        :if={@always_render_body || @modal_open}
        :on-click="nothing"
        class={"modal-box relative", "sm:w-11/12 sm:max-w-5xl lg:w-8/12": @big}
      >
        <div
          class="btn btn-circle btn-ghost close-modal absolute right-2 top-2 text-xl"
          :on-click="close_modal"
        >✕</div>
        {#if slot_assigned?(:title)}
          <h3 class="text-lg font-bold">
            <#slot name="title" />
          </h3>
        {/if}
        <#slot />
        {#if slot_assigned?(:action)}
          <div class="modal-action">
            <#slot name="action" />
          </div>
        {/if}
      </div>
    </div>
    """
  end
end
