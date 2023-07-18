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

  def render(assigns) do
    ~F"""
    <ul class="flex flex-col">
      {#for {item, idx} <- @line_items |> Enum.with_index()}
        <li class="flex flex-row py-2 gap-2">
          {#if @allow_edits && !item.sticky}
            <button
              type="button"
              class="hover:text-error w-8 text-xl opacity-50"
              :on-click={@remove_item}
              value={idx}
            >
              <Icon name="trash-2" />
            </button>
          {#else}
            <Icon name="check-circle-2" class="w-8 text-xl opacity-50" />
          {/if}
          <div class="grow w-full flex flex-col">
            <div class="font-medium text-sm">{item.name}</div>
            <div class="text-xs">{item.description}</div>
          </div>
          <div class="font-medium text-sm">{Payments.print_money(item.amount)}</div>
        </li>
      {/for}
    </ul>
    """
  end
end
