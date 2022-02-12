defmodule BanchanWeb.StudioLive.Components.RequestPaymentEvent do
  @moduledoc """
  This is what shows up on the commission timeline when an artist asks for payment.
  """
  use BanchanWeb, :live_component

  prop current_user, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true

  def render(assigns) do
    ~F"""
    <div class="shadow-lg bg-base-200 rounded-box border-2">
      <div class="p-4">
        {@event.actor.handle} requested payment of {Money.to_string(@event.amount)}
      </div>
    </div>
    """
  end
end
