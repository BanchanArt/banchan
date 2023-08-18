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
    <div class="flow-root snap-y">
      {!-- NB(@zkat): This is a load-bearing `overflow-visible` to fix anchor-links into timeline step events. --}
      <ul role="list" class="-mb-8 overflow-visible">
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
                          class="items-center justify-center w-10 h-10 border border-base-content border-opacity-10"
                          user={Map.get(@users, event.actor_id)}
                          link={false}
                        />
                      </div>
                      <article class="relative flex-1 min-w-0 scroll-mt-36 snap-start">
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
                  <span class="opacity-75">added</span> <span class="font-semibold">{event.text}</span> <span class="opacity-75">({Payments.print_money(event.amount)})</span>
                </TimelineItem>
              {#match :line_item_removed}
                <TimelineItem>
                  <:icon><Icon name="x" size={4} /></:icon>
                  <span class="opacity-75">removed</span> <span class="font-semibold">{event.text}</span> <span class="opacity-75">({Payments.print_money(Money.multiply(event.amount, -1))})</span>
                </TimelineItem>
              {#match :line_item_count_increased}
                <TimelineItem>
                  <:icon><Icon name="plus" size={4} /></:icon>
                  <span class="opacity-75">{event.text} ({Payments.print_money(event.amount)})</span>
                </TimelineItem>
              {#match :line_item_count_decreased}
                <TimelineItem>
                  <:icon><Icon name="minus" size={4} /></:icon>
                  <span class="opacity-75">{event.text} ({Payments.print_money(event.amount)})</span>
                </TimelineItem>
              {#match :payment_processed}
                <TimelineItem>
                  <:icon>{Payments.currency_symbol(event.amount)}</:icon>
                  <span class="opacity-75">paid</span> {Payments.print_money(event.amount)}
                </TimelineItem>
              {#match :refund_processed}
                <TimelineItem>
                  <:icon>{Payments.currency_symbol(event.amount)}</:icon>
                  <span class="opacity-75">refunded</span> {Payments.print_money(event.amount)}
                </TimelineItem>
              {#match :status}
                <TimelineItem>
                  <:icon><Icon name="info" size={4} /></:icon>
                  <span class="opacity-75">changed the status to</span> <span class="font-semibold">{Common.humanize_status(event.status)}</span>
                </TimelineItem>
              {#match :title_changed}
                <TimelineItem>
                  <:icon><Icon name="pencil" size={4} /></:icon>
                  <span class="opacity-75">changed the title from
                  </span><span class="line-through">{event.text}</span><span class="opacity-75">
                    to
                  </span>{@commission.title}
                </TimelineItem>
              {#match :invoice_released}
                <TimelineItem>
                  <:icon>{Payments.currency_symbol(event.amount)}</:icon>
                  <span class="opacity-75">released a deposit for
                  </span>{Payments.print_money(event.amount)}
                </TimelineItem>
              {#match :all_invoices_released}
                {#unless is_nil(event.amount)}
                  <TimelineItem>
                    <:icon>{Payments.currency_symbol(event.amount)}</:icon>
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
