defmodule BanchanWeb.StudioLive.Components.Commissions.TimelineItem do
  @moduledoc """
  Timeline Item
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Avatar

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
      <div class="items-center flex space-x-2">
        <Avatar class="w-6" user={@event.actor} />
        <span>
          <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @event.actor.handle)}>
            <strong class="hover:underline">{@event.actor.handle}</strong>
          </LiveRedirect>
          <#slot />
          <a class="hover:underline" href={replace_fragment(@uri, @event)}>{fmt_time(@event.inserted_at)}</a>.
        </span>
      </div>
    </div>
    """
  end
end
