defmodule BanchanWeb.Components.Collapse do
  @moduledoc """
  Collapsible content component.
  """
  use BanchanWeb, :live_component

  prop class, :css_class
  prop show_arrow, :boolean, default: true

  data open, :boolean, default: false

  slot header

  slot default

  def set_open(collapse_id, open) do
    send_update(__MODULE__, id: collapse_id, open: open)
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, open: !socket.assigns.open)}
  end

  def render(assigns) do
    ~F"""
    <div class={"flex flex-col", @class}>
      {#if slot_assigned?(:header)}
        <div class="flex flex-row items-center cursor-pointer" :on-click="toggle">
          <div class="grow">
            <#slot name="header" />
          </div>
          {#if @show_arrow}
            <i class={"fas", "fa-chevron-up": @open, "fa-chevron-down": !@open} />
          {/if}
        </div>
      {/if}
      <div class={"p-2", hidden: !@open}>
        <#slot />
      </div>
    </div>
    """
  end
end
