defmodule BanchanWeb.CommissionLive.Components.BalanceBox do
  @moduledoc """
  Displays a running balance based on the current line items + what's been
  deposited.
  """
  use BanchanWeb, :component

  prop default_currency, :atom, required: true
  prop line_items, :list, required: true
  prop deposited, :struct

  def render(assigns) do
    estimate =
      Enum.reduce(
        assigns.line_items,
        %{},
        fn item, acc ->
          current =
            Map.get(
              acc,
              item.amount.currency,
              Money.new(0, item.amount.currency)
            )

          Map.put(acc, item.amount.currency, Money.add(current, item.amount))
        end
      )

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

    ~F"""
    <div>
      {#if @deposited}
        <div class="p-2 flex flex-col gap-2">
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Quote:</div>
            <div class="flex flex-col">
              {#for val <- estimate}
                <div class="text-sm font-medium">
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Deposited:</div>
            <div class="flex flex-col">
              {#for val <- deposited}
                <div class="text-sm font-medium">
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Balance:</div>
            <div class="flex flex-col">
              {#for val <- remaining}
                <div class="text-sm font-medium">
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
        </div>
      {#else}
        <div class="px-2 flex">
          <div class="font-medium grow">Quote:</div>
          <div class="flex flex-col">
            {#for val <- estimate}
              <div class="text-sm font-medium">
                {Money.to_string(val)}
              </div>
            {/for}
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
