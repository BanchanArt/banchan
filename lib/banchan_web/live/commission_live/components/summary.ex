defmodule BanchanWeb.CommissionLive.Components.Summary do
  @moduledoc """
  Summary card for the Commissions Page sidebar
  """
  use BanchanWeb, :component

  alias Banchan.Payments

  alias BanchanWeb.Components.Icon

  prop(commission, :struct, from_context: :commission)
  prop(line_items, :list, required: true)
  prop(allow_edits, :boolean, default: false)
  prop(remove_item, :event)
  prop(increase_item, :event)
  prop(decrease_item, :event)

  def render(assigns) do
    ~F"""
    <ul class="flex flex-col">
      {#for {item, idx} <- @line_items |> Enum.with_index()}
        <li class="flex flex-row gap-4 py-2">
          {#if @allow_edits && !item.sticky}
            <button
              type="button"
              class="w-8 text-xl opacity-50 hover:text-error"
              :on-click={@remove_item}
              value={idx}
            >
              <Icon name="trash-2" />
            </button>
          {#else}
            <Icon name="check-circle-2" class="w-8 text-xl opacity-50" />
          {/if}
          <div class="flex flex-col w-full grow">
            <div class="text-sm font-medium">{item.name}</div>
            <div class="text-xs opacity-75">{item.description}</div>
            {#if item.multiple}
              <span class="inline-flex items-center w-24 pt-2 rounded-md isolate">
                <button
                  type="button"
                  :if={@allow_edits}
                  :on-click={@decrease_item}
                  value={idx}
                  class="relative inline-flex items-center px-2 py-1 rounded-l-md ring-1 ring-inset ring-base-300 focus:z-10 bg-base-200 text-content hover:bg-error hover:opacity-75 hover:text-base-100"
                >
                  <span class="sr-only">Previous</span>
                  <Icon name="minus" />
                </button>
                <span class="relative inline-flex items-center px-4 py-1 ring-1 ring-inset ring-base-300 focus:z-10 bg-base-100">{item.count}</span>
                <button
                  type="button"
                  :if={@allow_edits}
                  :on-click={@increase_item}
                  value={idx}
                  class="relative inline-flex items-center px-2 py-1 -ml-px rounded-r-md ring-1 ring-inset ring-base-300 focus:z-10 bg-base-200 text-content hover:bg-success hover:opacity-75 hover:text-base-100"
                >
                  <span class="sr-only">Next</span>
                  <Icon name="plus" />
                </button>
              </span>
            {/if}
          </div>
          <div class="font-medium">{Payments.print_money(Money.multiply(item.amount, item.count || 1))}</div>
        </li>
      {/for}
    </ul>
    """
  end
end
