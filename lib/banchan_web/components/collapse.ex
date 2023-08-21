defmodule BanchanWeb.Components.Collapse do
  @moduledoc """
  Collapsible content component.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Icon

  prop class, :css_class
  prop show_arrow, :boolean, default: true
  prop initial_open, :boolean, default: false

  data open, :boolean

  slot header

  slot default

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    if is_nil(socket.assigns[:open]) do
      {:ok, assign(socket, open: socket.assigns.initial_open)}
    else
      {:ok, socket}
    end
  end

  def set_open(collapse_id, open) do
    send_update(__MODULE__, id: collapse_id, open: open)
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, open: !socket.assigns.open)}
  end

  def render(assigns) do
    ~F"""
    <div class={"flex flex-col gap-2", @class}>
      {#if slot_assigned?(:header)}
        <div class="flex flex-row items-center cursor-pointer" :on-click="toggle">
          <div class="py-2 grow">
            <#slot {@header} />
          </div>
          {#if @show_arrow}
            <div class="p-2 opacity-50">
              <Icon name={(@open && "chevron-up") || "chevron-down"} size="4" />
            </div>
          {/if}
        </div>
      {/if}
      <div class={hidden: !@open}>
        <#slot />
      </div>
    </div>
    """
  end
end
