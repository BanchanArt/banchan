defmodule BanchanWeb.StudioLive.Components.Commissions.TimelineItem do
  @moduledoc """
  Timeline Item
  """
  use BanchanWeb, :component

  alias BanchanWeb.Endpoint

  prop event, :struct, required: true
  prop icon, :string, default: ""

  slot default

  def render(assigns) do
    ~F"""
    <div data-content={@icon} class="timeline-item step">
      <p>
        <img
          class="w-6 inline-block mask mask-circle"
          src={Routes.profile_image_path(Endpoint, :thumb, @event.actor.handle)}
        />
        <a href={"/denizens/#{@event.actor.handle}"}><strong>{@event.actor.handle}</strong></a>
        <#slot />
      </p>
    </div>
    """
  end
end
