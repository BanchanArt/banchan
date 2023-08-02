defmodule BanchanWeb.Components.OfferingCardImg do
  @moduledoc """
  The image that goes inside an offering card. Used in some contexts outside of cards themselves.
  """
  use BanchanWeb, :component

  alias Phoenix.LiveView.UploadEntry

  prop image, :any
  prop blur?, :boolean, default: false

  def render(assigns) do
    ~F"""
    <div class="relative">
      {#case @image}
        {#match %UploadEntry{}}
          <div class="absolute z-10 w-full h-full overflow-hidden">
            <.live_img_preview
              class={
                "object-contain aspect-video w-full h-full",
                "blur-lg": @blur?
              }
              draggable="false"
              entry={@image}
            />
          </div>
          <.live_img_preview
            class="object-contain w-full h-full aspect-video blur-2xl"
            draggable="false"
            entry={@image}
          />
        {#match _}
          <div class="absolute z-10 w-full h-full overflow-hidden">
            <img
              class={
                "object-contain aspect-video w-full h-full",
                "blur-lg": @blur?
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
            class="object-contain w-full h-full aspect-video blur-2xl"
            draggable="false"
            src={if @image do
              ~p"/images/offering_card_img/#{@image}"
            else
              ~p"/images/640x360.png"
            end}
          />
      {/case}
    </div>
    """
  end
end
