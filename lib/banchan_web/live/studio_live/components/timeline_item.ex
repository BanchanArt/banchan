defmodule BanchanWeb.StudioLive.Components.Commissions.TimelineItem do
  @moduledoc """
  Timeline Item
  """
  use BanchanWeb, :component

  alias BanchanWeb.Endpoint

  prop event, :struct, required: true
  prop icon, :string, default: ""
  prop uri, :string, required: true

  slot default

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  def render(assigns) do
    ~F"""
    <div id={"event-#{@event.public_id}"} data-content={@icon} class="timeline-item step">
      <p>
        <a href={"/denizens/#{@event.actor.handle}"}>
          <img
            class="w-6 inline-block mask mask-circle"
            src={Routes.profile_image_path(Endpoint, :thumb, @event.actor.handle)}
          />
          <strong class="hover:underline">{@event.actor.handle}</strong></a>
        <#slot />
        <a class="hover:underline" href={replace_fragment(@uri, @event)}>{fmt_time(@event.inserted_at)}</a>.
      </p>
    </div>
    """
  end
end
