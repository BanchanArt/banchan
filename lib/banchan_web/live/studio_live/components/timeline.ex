defmodule BanchanWeb.StudioLive.Components.Commissions.Timeline do
  @moduledoc """
  Main component for the Commission Page's timeline.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions.Common

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

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
                    <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                    {event.actor.handle} commented {fmt_time(event.inserted_at)}.
                  </:header>

                  <div class="content">
                    {raw(fmt_md(event.text))}
                  </div>
                </Card>
              </article>
            {/for}
          </div>
        {#else}
          <div class="steps steps-vertical">
            {#for event <- chunk}
              <div data-content="" class="timeline-item step">
                <p>
                  {#case event.type}
                    {#match :line_item_added}
                      <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                      <a href={"/denizens/#{event.actor.handle}"}><strong>{event.actor.handle}</strong></a>
                      added <strong>{event.text}</strong> ({Money.to_string(event.amount)}) {fmt_time(event.inserted_at)}.
                    {#match :line_item_removed}
                      <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                      <a href={"/denizens/#{event.actor.handle}"}><strong>{event.actor.handle}</strong></a>
                      removed <strong>{event.text}</strong> ({Money.to_string(Money.multiply(event.amount, -1))}) {fmt_time(event.inserted_at)}.
                    {#match :payment_request}
                      <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                      <a href={"/denizens/#{event.actor.handle}"}><strong>{event.actor.handle}</strong></a>
                      requested payment of {Money.to_string(event.amount)} {fmt_time(event.inserted_at)}.
                    {#match :status}
                      <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                      <a href={"/denizens/#{event.actor.handle}"}><strong>{event.actor.handle}</strong></a>
                      changed the status to <strong>{Common.humanize_status(event.status)}</strong> {fmt_time(event.inserted_at)}.
                    {#match :attachment}
                      <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                      <a href={"/denizens/#{event.actor.handle}"}><strong>{event.actor.handle}</strong></a>
                      added an attachment {fmt_time(event.inserted_at)}.
                  {/case}
                </p>
              </div>
            {/for}
          </div>
        {/if}
      {/for}
    </div>
    """
  end
end
