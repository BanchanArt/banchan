defmodule BanchanWeb.CommissionLive.Components.TimelineItem do
  @moduledoc """
  Timeline Item
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.{Avatar, UserHandle}

  prop actor, :struct, from_context: :actor
  prop event, :struct, from_context: :event
  prop uri, :string, from_context: :uri
  prop last?, :boolean, from_context: :last?

  slot icon, required: true
  slot default, required: true

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
    <li id={"event-#{@event.public_id}"} class="scroll-mt-36 snap-start">
      <div class="relative pb-8">
        {#if !@last?}
          <span
            class="absolute left-5 top-5 -ml-px h-full w-0.5 bg-base-content opacity-10"
            aria-hidden="true"
          />
        {/if}
        <div class="relative flex items-start space-x-3">
          <div>
            <div class="relative px-1">
              <div class="flex h-8 w-8 items-center justify-center rounded-full bg-base-200 ring-base-100 border-2 border-base-content border-opacity-10">
                <span class="text-base-content opacity-50 text-center align-middle" aria-hidden="true">
                  <#slot {@icon} />
                </span>
              </div>
            </div>
          </div>
          <div class="min-w-0 flex-1 py-1.5">
            <div class="text-xs text-base-content">
              <div class="inline-flex items-baseline space-x-1">
                <div class="self-center">
                  <Avatar class="w-4" user={@actor} />
                </div>
                <UserHandle user={@actor} />
              </div>
              <#slot />
              <a
                title={fmt_abs_time(@event.inserted_at)}
                class="hover:underline whitespace-nowrap"
                href={replace_fragment(@uri, @event)}
              >{fmt_time(@event.inserted_at)}</a>.
            </div>
          </div>
        </div>
      </div>
    </li>
    """
  end
end
