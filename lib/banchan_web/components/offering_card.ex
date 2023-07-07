defmodule BanchanWeb.Components.OfferingCard do
  @moduledoc """
  "Lower-level" plain component for displaying offering card content consistently.
  """
  use BanchanWeb, :component

  alias Phoenix.LiveView.UploadEntry

  alias BanchanWeb.Components.Card

  prop current_user, :any, from_context: :current_user
  prop name, :string
  prop image, :any
  prop base_price, :struct
  prop archived?, :boolean, default: false
  prop mature?, :boolean, default: false
  prop open?, :boolean, default: false
  prop hidden?, :boolean, default: false
  prop total_slots, :integer
  prop available_slots, :integer
  prop hover_grow?, :boolean, default: true

  def render(assigns) do
    ~F"""
    <Card
      class={
        "h-full transition-all relative",
        "opacity-50": @archived?,
        "sm:hover:scale-105 sm:hover:z-10": @hover_grow?
      }
      image_class="overflow-hidden"
    >
      <:header>
        <div class="text-sm sm:text-lg font-bold">{@name}</div>
      </:header>
      <:image>
        {#case @image}
          {#match %UploadEntry{}}
            <div class="absolute overflow-hidden z-10">
              <.live_img_preview
                class={
                  "object-contain aspect-video w-full h-full",
                  "blur-lg": @mature? && !@current_user.uncensored_mature
                }
                draggable="false"
                entry={@image}
              />
            </div>
            <.live_img_preview class="aspect-video w-full h-full blur-lg" draggable="false" entry={@image} />
          {#match _}
            <div class="absolute overflow-hidden z-10">
              <img
                class={
                  "object-contain aspect-video w-full h-full",
                  "blur-lg": @mature? && !@current_user.uncensored_mature
                }
                draggable="false"
                src={if @image do
                  ~p"/images/offering_card_img/#{@image}"
                else
                  ~p"/images/640x360.png"
                end}
              />
            </div>
            <img
              class="aspect-video w-full h-full blur-lg"
              draggable="false"
              src={if @image do
                ~p"/images/offering_card_img/#{@image}"
              else
                ~p"/images/640x360.png"
              end}
            />
        {/case}
      </:image>
      <div class="absolute top-4 right-4 flex flex-col flex-wrap gap-2 items-end z-10">
        {#if @open? && !is_nil(@total_slots) && !is_nil(@available_slots)}
          <div class="whitespace-nowrap badge badge-primary shadow-md shadow-black">{@available_slots}/{@total_slots} Slots</div>
        {#elseif !@open? && !is_nil(@total_slots)}
          <div class="badge badge-error shadow-md shadow-black">0/{@total_slots} Slots</div>
        {#elseif @open?}
          <div class="badge badge-primary shadow-md shadow-black">Open</div>
        {#else}
          <div class="badge badge-error shadow-md shadow-black">Closed</div>
        {/if}
        {#if @mature?}
          <div class="badge badge-error shadow-md shadow-black">Mature</div>
        {/if}
        {#if @hidden?}
          <div class="badge badge-error shadow-md shadow-black">Hidden</div>
        {/if}
      </div>

      <div class="flex flex-col gap-2 grow justify-end">
        <div class="flex flex-col z-20">
          <p class="flex flex-row items-end">
            <span class="font-bold grow">Base Price:</span>
            {#if is_nil(@base_price)}
              <span class="font-semibold">Inquire</span>
            {#else}
              <span class="font-semibold">{Money.to_string(@base_price)}</span>
            {/if}
          </p>
        </div>
      </div>
    </Card>
    """
  end
end
