defmodule BanchanWeb.CommissionLive.Components.Timeline do
  @moduledoc """
  Main component for the Commission Page's timeline.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common
  alias Banchan.Payments

  alias BanchanWeb.CommissionLive.Components.{Comment, TimelineItem}

  prop users, :map, required: true
  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :any, from_context: :commission
  prop report_modal_id, :string, required: true

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
        &(&1.type == :comment)
      )

    ~F"""
    <div class="snap-y">
      {#for chunk <- event_chunks}
        {#if List.first(chunk).type == :comment}
          <div class="flex flex-col space-y-4">
            {#for event <- chunk}
              <article class="timeline-item scroll-mt-36 snap-start" id={"event-#{event.public_id}"}>
                <Comment
                  id={"event-#{event.public_id}"}
                  actor={Map.get(@users, event.actor_id)}
                  event={event}
                  report_modal_id={@report_modal_id}
                />
              </article>
            {/for}
          </div>
        {#else}
          {!-- NB(@zkat): This is a load-bearing `overflow-visible` to fix anchor-links into timeline step events. --}
          <div class="steps steps-vertical overflow-visible">
            {#for event <- chunk}
              {#case event.type}
                {#match :line_item_added}
                  <TimelineItem icon="➕" actor={Map.get(@users, event.actor_id)} event={event}>
                    added <strong>{event.text}</strong> ({Payments.print_money(event.amount)})
                  </TimelineItem>
                {#match :line_item_removed}
                  <TimelineItem icon="✖" actor={Map.get(@users, event.actor_id)} event={event}>
                    removed <strong>{event.text}</strong> ({Payments.print_money(Money.multiply(event.amount, -1))})
                  </TimelineItem>
                {#match :payment_processed}
                  <TimelineItem
                    icon={Money.Currency.symbol(event.amount)}
                    actor={Map.get(@users, event.actor_id)}
                    event={event}
                  >
                    paid {Payments.print_money(event.amount)}
                  </TimelineItem>
                {#match :refund_processed}
                  <TimelineItem
                    icon={Money.Currency.symbol(event.amount)}
                    actor={Map.get(@users, event.actor_id)}
                    event={event}
                  >
                    refunded {Payments.print_money(event.amount)}
                  </TimelineItem>
                {#match :status}
                  <TimelineItem icon="S" actor={Map.get(@users, event.actor_id)} event={event}>
                    changed the status to <strong>{Common.humanize_status(event.status)}</strong>
                  </TimelineItem>
                {#match :title_changed}
                  <TimelineItem icon="T" actor={Map.get(@users, event.actor_id)} event={event}>
                    changed the title <span class="line-through">{event.text}</span> {@commission.title}
                  </TimelineItem>
                {#match :invoice_released}
                  <TimelineItem
                    icon={Money.Currency.symbol(event.amount)}
                    actor={Map.get(@users, event.actor_id)}
                    event={event}
                  >
                    released a deposit for {Payments.print_money(event.amount)}
                  </TimelineItem>
                {#match :all_invoices_released}
                  {#unless is_nil(event.amount)}
                    <TimelineItem
                      icon={Money.Currency.symbol(event.amount)}
                      actor={Map.get(@users, event.actor_id)}
                      event={event}
                    >
                      released all deposits, totaling {Payments.print_money(event.amount)}
                    </TimelineItem>
                  {/unless}
              {/case}
            {/for}
          </div>
        {/if}
      {/for}
    </div>
    """
  end
end
