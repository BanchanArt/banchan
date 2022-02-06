defmodule BanchanWeb.StudioLive.Components.Commissions.Timeline do
  @moduledoc """
  Main component for the Commission Page's timeline.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions.Common

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.Commissions.TimelineItem

  prop studio, :struct, required: true
  prop commission, :any, required: true

  def fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  def fmt_md(md) do
    HtmlSanitizeEx.markdown_html(Earmark.as_html!(md || ""))
  end

  def render(assigns) do
    event_chunks = Enum.chunk_by(assigns.commission.events, &(&1.type == :comment))

    ~F"""
    <div class="timeline">
      {#for chunk <- event_chunks}
        {#if List.first(chunk).type == :comment}
          <div>
            {#for event <- chunk}
              <article class="timeline-item">
                <Card>
                  <:header>
                    <img
                      class="w-6 inline-block mask mask-circle"
                      src={Routes.profile_image_path(Endpoint, :thumb, event.actor.handle)}
                    />
                    {event.actor.handle} commented {fmt_time(event.inserted_at)}.
                  </:header>

                  <div class="content">
                    {raw(fmt_md(event.text))}
                  </div>

                  <:footer>
                    Attachments:
                    <ul>
                      {#for attachment <- event.attachments}
                        <li>
                          <a
                            target="_blank"
                            href={Routes.commission_attachment_path(
                              Endpoint,
                              :show,
                              @studio.handle,
                              @commission.public_id,
                              attachment.upload.key
                            )}
                          >
                            {#if IO.inspect(attachment.thumbnail)}
                              <img src={Routes.commission_attachment_path(
                                Endpoint,
                                :thumbnail,
                                @studio.handle,
                                @commission.public_id,
                                attachment.upload.key
                              )}>
                            {#else}
                              {attachment.upload.name}
                            {/if}
                          </a>
                        </li>
                      {/for}
                    </ul>
                  </:footer>
                </Card>
              </article>
            {/for}
          </div>
        {#else}
          <div class="steps steps-vertical">
            {#for event <- chunk}
              {#case event.type}
                {#match :line_item_added}
                  <TimelineItem icon="➕" event={event}>
                    added <strong>{event.text}</strong> ({Money.to_string(event.amount)}) {fmt_time(event.inserted_at)}.
                  </TimelineItem>
                {#match :line_item_removed}
                  <TimelineItem icon="✕" event={event}>
                    removed <strong>{event.text}</strong> ({Money.to_string(Money.multiply(event.amount, -1))}) {fmt_time(event.inserted_at)}.
                  </TimelineItem>
                {#match :payment_request}
                  <TimelineItem icon="$" event={event}>
                    requested payment of {Money.to_string(event.amount)} {fmt_time(event.inserted_at)}.
                  </TimelineItem>
                {#match :payment_processed}
                  <TimelineItem icon="$" event={event}>
                    paid {Money.to_string(event.amount)} {fmt_time(event.inserted_at)}.
                  </TimelineItem>
                {#match :status}
                  <TimelineItem icon="S" event={event}>
                    changed the status to <strong>{Common.humanize_status(event.status)}</strong> {fmt_time(event.inserted_at)}.
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
