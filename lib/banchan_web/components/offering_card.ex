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
  prop studio_name, :string

  def render(assigns) do
    ~F"""
    <offering-card class={
      "group h-full transition-all relative flex flex-col border rounded-lg border-base-content border-opacity-10 p-0 m-0 sm:hover:outline sm:hover:outline-primary-focus sm:hover:outline-3 sm:hover:outline-offset-0 sm:hover:border-primary-focus",
      "opacity-50": @archived?
    }>
      <div class="rounded-t-lg stack-custom">
        <div class="px-2 py-1 text-sm text-right rounded-tl-lg h-fit w-fit availability-status whitespace-nowrap bg-base-300">
          {#if @open? && !is_nil(@total_slots) && !is_nil(@available_slots)}
            {@available_slots}/{@total_slots} Slots
          {#elseif @open?}
            Open
          {#else}
            Closed
          {/if}
        </div>
        <figure class="overflow-hidden rounded-t-lg bg-base-300/25">
          <OfferingCardImg blur?={@mature? && !@uncensored?} image={@image} />
        </figure>
      </div>
      <div class="flex flex-col px-4 py-2 rounded-b-lg bg-base-100 align-items-center">
        <div class="flex flex-col">
          <div class="flex flex-row max-w-full gap-2">
            <span class="font-bold truncate name text-md">{@name}</span>
            {#if @mature?}
              <span
                title="Mature"
                class="flex flex-row items-center px-1 py-px text-xs font-bold bg-opacity-75 border rounded-md bg-error text-error-content border-base-content border-opacity-10"
              >M</span>
            {/if}
            {#if @hidden?}
              <span
                title="Hidden"
                class="flex flex-row items-center px-1 py-px text-xs font-bold bg-opacity-75 border rounded-md bg-warning text-warning-content border-base-content border-opacity-10"
              >Hidden</span>
            {/if}
          </div>
          <div class="flex flex-row items-end gap-2">
            <div :if={@studio_name} class="text-xs opacity-75 grow">
              By <span class="font-semibold">{@studio_name}</span>
            </div>
            <div
              :if={@show_base_price?}
              class="flex flex-col justify-center text-sm font-bold whitespace-nowrap"
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
        </div>
      </div>
    </offering-card>
    """
  end
end
