defmodule BanchanWeb.StudioLive.Components.Commissions.Timeline do
  @moduledoc """
  Main component for the Commission Page's timeline.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common

  alias BanchanWeb.StudioLive.Components.{Comment, RequestPaymentEvent}
  alias BanchanWeb.StudioLive.Components.Commissions.TimelineItem

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop studio, :struct, required: true
  prop commission, :any, required: true
  prop uri, :string, required: true

  def fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  def fmt_md(md) do
    HtmlSanitizeEx.markdown_html(Earmark.as_html!(md || ""))
  end

  def render(assigns) do
    event_chunks =
      Enum.chunk_by(
        assigns.commission.events,
        &(&1.type == :comment || &1.type == :payment_requested)
      )

    ~F"""
    <div class="timeline">
      {#for chunk <- event_chunks}
        {#if List.first(chunk).type == :comment || List.first(chunk).type == :payment_requested}
          <div class="flex flex-col space-y-4">
            {#for event <- chunk}
              <article class="timeline-item" id={"event-#{event.public_id}"}>
                {#if event.type == :comment}
                  <Comment
                    id={"event-#{event.public_id}"}
                    uri={@uri}
                    studio={@studio}
                    event={event}
                    commission={@commission}
                    current_user={@current_user}
                    current_user_member?={@current_user_member?}
                  />
                {#elseif event.type == :payment_requested}
                  <RequestPaymentEvent
                    id={"event-#{event.public_id}"}
                    uri={@uri}
                    current_user={@current_user}
                    commission={@commission}
                    event={event}
                  />
                {/if}
              </article>
            {/for}
          </div>
        {#else}
          <div class="steps steps-vertical">
            {#for event <- chunk}
              {#case event.type}
                {#match :line_item_added}
                  <TimelineItem uri={@uri} icon="➕" event={event}>
                    added <strong>{event.text}</strong> ({Money.to_string(event.amount)})
                  </TimelineItem>
                {#match :line_item_removed}
                  <TimelineItem uri={@uri} icon="✕" event={event}>
                    removed <strong>{event.text}</strong> ({Money.to_string(Money.multiply(event.amount, -1))})
                  </TimelineItem>
                {#match :payment_processed}
                  <TimelineItem uri={@uri} icon="$" event={event}>
                    paid {Money.to_string(event.amount)}
                  </TimelineItem>
                {#match :status}
                  <TimelineItem uri={@uri} icon="S" event={event}>
                    changed the status to <strong>{Common.humanize_status(event.status)}</strong>
                  </TimelineItem>
              {/case}
            {/for}
          </div>
        {/if}
      {/for}
    </div>
    """
  end
end
