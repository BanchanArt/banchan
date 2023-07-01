defmodule BanchanWeb.CommissionLive.Components.BalanceBox do
  @moduledoc """
  Displays a running balance based on the current line items + what's been
  deposited.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions

  prop default_currency, :atom, required: true
  prop line_items, :list, required: true
  prop deposited, :struct
  prop amount_due, :boolean, default: false

  data estimate_amt, :list
  data deposited_amt, :list
  data remaining_amt, :list

  def update(assigns, socket) do
    estimate = Commissions.line_item_estimate(assigns.line_items)

    deposited =
      if is_nil(assigns.deposited) || Enum.empty?(assigns.deposited) do
        [Money.new(0, assigns.default_currency)]
      else
        assigns.deposited |> Map.values()
      end

    remaining =
      if is_nil(assigns.deposited) || Enum.empty?(assigns.deposited) do
        Map.values(estimate)
      else
        assigns.deposited
        |> Enum.map(fn {currency, amount} ->
          Money.subtract(Map.get(estimate, currency, Money.new(0, currency)), amount)
        end)
      end

    estimate = Map.values(estimate)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       estimate_amt: estimate,
       deposited_amt: deposited,
       remaining_amt: remaining
     )}
  end

  def render(assigns) do
    ~F"""
    <div>
      {#if @deposited}
        <div class="p-2 flex flex-col gap-2">
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Subtotal:</div>
            <div class="flex flex-col">
              {#for val <- @estimate_amt}
                <div class="text-sm font-medium">
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Deposited:</div>
            <div class="flex flex-col">
              {#for val <- @deposited_amt}
                <div class="text-sm font-medium">
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
          <div class="flex flex-row items-center">
            <div class="font-bold grow">
              {#if @amount_due}
                Amount Due:
              {#else}
                Balance:
              {/if}
            </div>
            <div class="flex flex-col">
              {#for val <- @remaining_amt}
                <div class="text-md font-bold text-primary">
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
        </div>
      {#else}
        <div class="px-2 flex flex-row">
          <div class="font-medium grow">Subtotal:</div>
          {#if Enum.empty?(@estimate_amt)}
            <span class="font-medium">TBD</span>
          {#else}
            <div class="flex flex-col">
              {#for val <- @estimate_amt}
                <div class="text-sm font-medium">
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          {/if}
        </div>
      {/if}
    </div>
    """
  end
end
