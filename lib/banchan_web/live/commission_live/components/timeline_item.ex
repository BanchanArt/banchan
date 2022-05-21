defmodule BanchanWeb.CommissionLive.Components.Commissions.TimelineItem do
  @moduledoc """
  Timeline Item
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.{Avatar, UserHandle}

  prop event, :struct, required: true
  prop icon, :string, default: ""
  prop uri, :string, required: true

  slot default

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp fmt_abs_time(time) do
    time |> Timex.to_datetime() |> Timex.format!("{RFC822}")
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  def render(assigns) do
    ~F"""
    <div id={"event-#{@event.public_id}"} data-content={@icon} class="step">
      <div class="text-xs text-left">
        <div class="inline-flex items-baseline space-x-1">
          <div class="self-center">
            <Avatar class="w-4" user={@event.actor} />
          </div>
          <UserHandle user={@event.actor} />
        </div>
        <#slot />
        <a
          title={"#{fmt_abs_time(@event.inserted_at)}"}
          class="hover:underline"
          href={replace_fragment(@uri, @event)}
        >{fmt_time(@event.inserted_at)}</a>.
      </div>
    </div>
    """
  end
end
