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
              <div class="flex items-center justify-center w-8 h-8 my-0.5 border-2 rounded-full bg-base-200 ring-base-100 border-base-content border-opacity-10">
                <span class="text-center align-middle opacity-50 text-base-content" aria-hidden="true">
                  <#slot {@icon} />
                </span>
              </div>
            </div>
          </div>
          <div class="flex-1 min-w-0 py-2">
            <div class="flex flex-row flex-wrap items-center gap-1 text-sm text-base-content">
              <div class="inline-flex items-center gap-2">
                <Avatar class="w-4" user={@actor} />
                <UserHandle user={@actor} />
              </div>
              <#slot />
              <a
                title={fmt_abs_time(@event.inserted_at)}
                class="opacity-75 hover:underline whitespace-nowrap hover:opacity-100"
                href={replace_fragment(@uri, @event)}
              >{fmt_time(@event.inserted_at)}</a>
            </div>
          </div>
        </div>
      </div>
    </li>
    """
  end
end
