defmodule BanchanWeb.CommissionLive.Components.BalanceBox do
  @moduledoc """
  Displays a running balance based on the current line items + what's been
  deposited.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions

  prop line_items, :list, required: true
  prop deposited, :struct
  prop invoiced, :boolean, default: false
  prop tipped, :struct

  data estimate_amt, :list
  data deposited_amt, :list
  data remaining_amt, :list

  def update(assigns, socket) do
    estimate = Commissions.line_item_estimate(assigns.line_items)

    deposited = assigns.deposited || Money.new(0, estimate.currency)

    remaining = Money.subtract(estimate, deposited)

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
            <div class="text-sm font-medium">
              {Money.to_string(@estimate_amt)}
            </div>
          </div>
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Deposited:</div>
            <div class="text-sm font-medium">
              {Money.to_string(@deposited_amt)}
            </div>
          </div>
          {#if @tipped}
            <div class="flex flex-row items-center">
              <div class="font-medium grow">Tipped:</div>
              <div class="text-sm font-medium">
                {Money.to_string(@tipped)}
              </div>
            </div>
          {/if}
          <div class="flex flex-row items-center">
            <div class="font-bold grow">
              {#if @invoiced}
                Invoiced:
              {#else}
                Balance:
              {/if}
            </div>
            <div class={"text-md font-bold", "text-primary": @remaining_amt.amount > 0, "text-error": @remaining_amt.amount < 0}>
              {Money.to_string(@remaining_amt)}
            </div>
          </div>
        </div>
      {#else}
        <div class="px-2 flex flex-row">
          <div class="font-medium grow">Subtotal:</div>
          <div class="text-sm font-medium">
            {Money.to_string(@estimate_amt)}
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
