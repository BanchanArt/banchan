defmodule BanchanWeb.CommissionLive.Components.Timeline do
  @moduledoc """
  Main component for the Commission Page's timeline.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common
  alias Banchan.Payments

  alias Surface.Components.Context

  alias BanchanWeb.CommissionLive.Components.{Comment, TimelineItem}
  alias BanchanWeb.Components.{Avatar, Icon}

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
    ~F"""
    <div class="snap-y flow-root">
      {!-- NB(@zkat): This is a load-bearing `overflow-visible` to fix anchor-links into timeline step events. --}
      <ul role="list" class="py-8 -mb-8 overflow-visible">
        {#for {event, idx} <- @commission.events |> Enum.with_index()}
          <Context put={
            last?: idx == Enum.count(@commission.events) - 1,
            event: event,
            actor: Map.get(@users, event.actor_id)
          }>
            {#case event.type}
              {#match :comment}
                <li id={"event-#{event.public_id}"} class="scroll-mt-36 snap-start">
                  <div class="relative pb-8">
                    {#if idx != Enum.count(@commission.events) - 1}
                      <span
                        class="absolute left-5 top-5 -ml-px h-full w-0.5 bg-base-content opacity-10"
                        aria-hidden="true"
                      />
                    {/if}
                    <div class="relative flex items-start md:space-x-3">
                      <div class="hidden md:flex">
                        <Avatar
                          class="h-10 w-10 items-center justify-center border border-base-300"
                          user={Map.get(@users, event.actor_id)}
                          link={false}
                        />
                      </div>
                      <article class="relative scroll-mt-36 snap-start min-w-0 flex-1">
                        <Comment
                          id={"event-#{event.public_id}"}
                          actor={Map.get(@users, event.actor_id)}
                          event={event}
                          report_modal_id={@report_modal_id}
                        />
                      </article>
                    </div>
                  </div>
                </li>
              {#match :line_item_added}
                <TimelineItem>
                  <:icon><Icon name="plus" size={4} /></:icon>
                  added <strong>{event.text}</strong> ({Payments.print_money(event.amount)})
                </TimelineItem>
              {#match :line_item_removed}
                <TimelineItem>
                  <:icon><Icon name="x" size={4} /></:icon>
                  removed <strong>{event.text}</strong> ({Payments.print_money(Money.multiply(event.amount, -1))})
                </TimelineItem>
              {#match :line_item_count_increased}
                <TimelineItem>
                  <:icon><Icon name="plus" size={4} /></:icon>
                  {event.text} ({Payments.print_money(event.amount)})
                </TimelineItem>
              {#match :line_item_count_decreased}
                <TimelineItem>
                  <:icon><Icon name="minus" size={4} /></:icon>
                  {event.text} ({Payments.print_money(event.amount)})
                </TimelineItem>
              {#match :payment_processed}
                <TimelineItem>
                  <:icon>{Money.Currency.symbol(event.amount)}</:icon>
                  paid {Payments.print_money(event.amount)}
                </TimelineItem>
              {#match :refund_processed}
                <TimelineItem>
                  <:icon>{Money.Currency.symbol(event.amount)}</:icon>
                  refunded {Payments.print_money(event.amount)}
                </TimelineItem>
              {#match :status}
                <TimelineItem>
                  <:icon><Icon name="replace" size={4} /></:icon>
                  changed the status to <strong>{Common.humanize_status(event.status)}</strong>
                </TimelineItem>
              {#match :title_changed}
                <TimelineItem>
                  <:icon><Icon name="pencil" size={4} /></:icon>
                  changed the title <span class="line-through">{event.text}</span> {@commission.title}
                </TimelineItem>
              {#match :invoice_released}
                <TimelineItem>
                  <:icon>{Money.Currency.symbol(event.amount)}</:icon>
                  released a deposit for {Payments.print_money(event.amount)}
                </TimelineItem>
              {#match :all_invoices_released}
                {#unless is_nil(event.amount)}
                  <TimelineItem>
                    <:icon>{Money.Currency.symbol(event.amount)}</:icon>
                    released all deposits, totaling {Payments.print_money(event.amount)}
                  </TimelineItem>
                {/unless}
            {/case}
          </Context>
        {/for}
      </ul>
    </div>
    """
  end
end
