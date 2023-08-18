defmodule BanchanWeb.CommissionLive.Components.BalanceBox do
  @moduledoc """
  Displays a running balance based on the current line items + what's been
  deposited.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Payments

  prop line_items, :list, required: true
  prop deposited, :struct
  prop invoiced, :struct
  prop tipped, :struct

  data estimate_amt, :list
  data deposited_amt, :list
  data remaining_amt, :list

  def update(assigns, socket) do
    estimate = Commissions.line_item_estimate(assigns.line_items)

    deposited = assigns.deposited || Money.new(0, estimate.currency)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       estimate_amt: estimate,
       deposited_amt: deposited,
       remaining_amt: assigns.invoiced || Money.subtract(estimate, deposited)
     )}
  end

  def render(assigns) do
    ~F"""
    <div class="text-sm">
      {#if @deposited}
        <div class="flex flex-col gap-2">
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Subtotal:</div>
            <div class="font-medium">
              {Payments.print_money(@estimate_amt)}
            </div>
          </div>
          <div class="flex flex-row items-center">
            <div class="font-medium grow">Deposited:</div>
            <div class="font-medium">
              {Payments.print_money(@deposited_amt)}
            </div>
          </div>
          {#if @tipped}
            <div class="flex flex-row items-center">
              <div class="font-medium grow">Tipped:</div>
              <div class="font-medium">
                {Payments.print_money(@tipped)}
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
            <div class={
              "font-bold",
              "text-primary": @remaining_amt.amount > 0,
              "text-error": @remaining_amt.amount < 0
            }>
              {Payments.print_money(@remaining_amt)}
            </div>
          </div>
        </div>
      {#else}
        <div class="flex flex-row">
          <div class="font-medium grow">Subtotal:</div>
          <div class="font-medium">
            {Payments.print_money(@estimate_amt)}
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
