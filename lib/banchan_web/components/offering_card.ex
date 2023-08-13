defmodule BanchanWeb.Components.OfferingCard do
  @moduledoc """
  "Lower-level" plain component for displaying offering card content consistently.
  """
  use BanchanWeb, :component

  alias Banchan.Payments

  alias BanchanWeb.Components.OfferingCardImg

  prop name, :string
  prop image, :any
  prop base_price, :struct
  prop has_addons?, :boolean, default: false
  prop show_base_price?, :boolean, default: true
  prop archived?, :boolean, default: false
  prop mature?, :boolean, default: false
  prop uncensored?, :boolean, default: false
  prop open?, :boolean, default: false
  prop hidden?, :boolean, default: false
  prop total_slots, :integer
  prop available_slots, :integer

  def render(assigns) do
    ~F"""
    <offering-card class={
      "h-full transition-all relative flex flex-col",
      "opacity-50": @archived?
    }>
      <figure class="overflow-hidden border rounded-lg border-base-content border-opacity-10 bg-base-300/25">
        <OfferingCardImg blur?={@mature? && !@uncensored?} image={@image} />
      </figure>
      <div class="flex flex-row pt-2 align-items-center">
        <div class="flex flex-col grow">
          <div class="flex flex-row gap-2 align-items-center">
            <span class="font-bold name text-md">{@name}</span>
            {#if @mature?}
              <span
                title="Mature"
                class="px-2 bg-error text-xs text-error-content rounded-md border border-base-content border-opacity-10 bg-opacity-75 flex flex-row items-center font-bold"
              >M</span>
            {/if}
            {#if @hidden?}
              <span
                title="Hidden"
                class="px-2 bg-warning text-xs text-warning-content rounded-md border border-base-content border-opacity-10 bg-opacity-75 flex flex-row items-center font-bold"
              >Hidden</span>
            {/if}
          </div>
          <div class="text-xs font-semibold opacity-75 availability-status whitespace-nowrap">
            {#if @open? && !is_nil(@total_slots) && !is_nil(@available_slots)}
              {@available_slots}/{@total_slots} Slots
            {#elseif @open?}
              Open
            {#else}
              Closed
            {/if}
          </div>
        </div>
        <div
          :if={@show_base_price?}
          class="flex flex-col justify-center text-lg font-bold whitespace-nowrap"
        >
          <span class="flex items-center gap-2">
            {#if is_nil(@base_price)}
              Inquire
            {#else}
              {#if @has_addons?}
                <span class="text-sm font-semibold opacity-80">From
                </span>
              {/if}
              <span class="flex gap-0">
                <span class="opacity-80">{Payments.currency_symbol(@base_price)}</span>
                {Payments.print_money(@base_price, false)}
              </span>
            {/if}
          </span>
        </div>
      </div>
    </offering-card>
    """
  end
end
