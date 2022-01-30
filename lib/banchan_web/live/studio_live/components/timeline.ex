defmodule BanchanWeb.StudioLive.Components.Commissions.Timeline do
  @moduledoc """
  Main component for the Commission Page's timeline.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  prop current_user, :any, required: true
  prop commission, :any, required: true

  def fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  def fmt_md(md) do
    HtmlSanitizeEx.markdown_html(Earmark.as_html!(md || ""))
  end

  def render(assigns) do
    ~F"""
    <div class="timeline">
      {#for event <- @commission.events}
        <article class="timeline-item">
          {#case event.type}
            {#match :comment}
              <Card>
                <:header>
                  <img class="w-6 inline-block" src={Routes.static_path(Endpoint, "/images/kat-chibi.jpeg")}>
                  {event.actor.handle} commented {fmt_time(event.inserted_at)}.
                </:header>

                <div class="content">
                  {raw(fmt_md(event.text))}
                </div>
              </Card>
            {#match :line_item}
              <p class="timeline-item block"><i class="fas fa-clipboard-check" /> {event.actor} added a line item {fmt_time(event.inserted_at)}.</p>
            {#match :payment_request}
              <p class="timeline-item block"><i class="fas fa-clipboard-check" /> {event.actor} requested payment of {Money.to_string(event.amount)} {fmt_time(event.inserted_at)}.</p>
            {#match :status}
              <p class="timeline-item block"><i class="fas fa-clipboard-check" /> {event.actor} changed the status of this commission to {to_string(event.status)} {fmt_time(event.inserted_at)}.</p>
            {#match :attachment}
              <p class="timeline-item block"><i class="fas fa-clipboard-check" /> {event.actor} added an attachment {fmt_time(event.inserted_at)}.</p>
          {/case}
        </article>
      {/for}
    </div>
    """
  end
end
