defmodule BanchanWeb.CommissionLive.Components.OfferingBox do
  @moduledoc """
  Shows a little box with a basic offering information/header image on the
  commissions page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.OfferingCard

  prop offering, :struct, required: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    {#if is_nil(@offering) || @offering.deleted_at || @offering.studio.deleted_at}
      <div class="px-2 text-lg font-medium">
        (Deleted Offering)
      </div>
    {#else}
      <LiveRedirect
        class={@class}
        to={Routes.offering_show_path(Endpoint, :show, @offering.studio.handle, @offering.type)}
      >
        {#if !is_nil(@offering.card_img_id)}
          <OfferingCard
            image={@offering.card_img_id}
            name={"#{@offering.name} by #{@offering.studio.name}"}
            show_pills?={false}
            show_base_price?={false}
          />
        {#else}
          <div class="px-2 text-lg">
            <span class="font-medium">{@offering.name}</span> by {@offering.studio.name}
          </div>
        {/if}
      </LiveRedirect>
    {/if}
    """
  end
end
