defmodule BanchanWeb.CommissionLive.Components.OfferingBox do
  @moduledoc """
  Shows a little box with a basic offering information/header image on the
  commissions page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.OfferingCard

  prop current_user, :struct, from_context: :current_user
  prop offering, :struct, required: true
  prop available_slots, :integer
  prop class, :css_class

  def render(assigns) do
    ~F"""
    {#if is_nil(@offering) || @offering.deleted_at || @offering.studio.deleted_at}
      <div class="px-2 text-sm font-medium opacity-75">
        (Deleted Offering)
      </div>
    {#else}
      <LiveRedirect
        class={@class}
        to={~p"/studios/#{@offering.studio.handle}/offerings/#{@offering.type}"}
      >
        {#if !is_nil(@offering.card_img_id)}
          <OfferingCard
            image={@offering.card_img_id}
            name={@offering.name}
            archived?={!is_nil(@offering.archived_at)}
            mature?={@offering.mature}
            uncensored?={@current_user.uncensored_mature}
            open?={@offering.open}
            hidden?={@offering.hidden}
            total_slots={@offering.slots}
            available_slots={@available_slots}
            show_base_price?={false}
          />
        {#else}
          <div class="text-sm">
            <span class="font-medium">{@offering.name}</span><span class="opacity-75">
              by {@offering.studio.name}</span>
          </div>
        {/if}
      </LiveRedirect>
    {/if}
    """
  end
end
