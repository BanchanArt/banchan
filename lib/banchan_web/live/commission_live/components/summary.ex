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
    <ul class="flex flex-col items-start w-full gap-4">
      {#for {item, idx} <- @line_items |> Enum.with_index()}
        <li class="flex flex-row items-center w-full gap-4">
          {#if @allow_edits && !item.sticky}
            <button
              type="button"
              class="w-8 text-xl opacity-50 hover:opacity-100 hover:text-error"
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
              <span class="flex items-center mt-2 border rounded-md h-fit w-fit isolate border-base-content border-opacity-10">
                <button
                  type="button"
                  :if={@allow_edits}
                  :on-click={@decrease_item}
                  value={idx}
                  class="relative flex items-center h-8 px-2 py-1 rounded-l-md focus:z-10 bg-base-200 text-content hover:bg-error hover:opacity-75 hover:text-base-100"
                >
                  <span class="sr-only">Previous</span>
                  <Icon name="minus" size="4" />
                </button>
                <span class="relative flex items-center h-8 px-4 py-1 focus:z-10 bg-base-100 border-x border-base-content border-opacity-10">{item.count}</span>
                <button
                  type="button"
                  :if={@allow_edits}
                  :on-click={@increase_item}
                  value={idx}
                  class="relative flex items-center h-8 px-2 py-1 -ml-px rounded-r-md focus:z-10 bg-base-200 text-content hover:bg-success hover:opacity-75 hover:text-base-100"
                >
                  <span class="sr-only">Next</span>
                  <Icon name="plus" size="4" />
                </button>
              </span>
            {/if}
          </div>
          <div class="text-sm font-medium">{Payments.print_money(Money.multiply(item.amount, item.count || 1))}</div>
        </li>
      {/for}
    </ul>
    """
  end
end
