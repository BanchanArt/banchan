defmodule BanchanWeb.StudioLive.Components.PayoutList do
  @moduledoc """
  Displays a list of Payouts for a Studio.
  """
  use BanchanWeb, :component

  alias Banchan.Payments
  alias Banchan.Payments.Payout

  alias Surface.Components.LivePatch

  alias BanchanWeb.Components.Icon

  prop studio, :struct, required: true
  prop payouts, :list, required: true
  prop payout_id, :string, required: true

  defp status_color(status) do
    case status do
      :pending -> "bg-warning"
      :in_transit -> "bg-warning"
      :canceled -> "bg-error"
      :paid -> "bg-success"
      :failed -> "bg-error"
    end
  end

  def render(assigns) do
    ~F"""
    <ul
      role="list"
      class="payout-rows divide-y divide-base-200 overflow-hidden rounded-box rounded-r-none"
    >
      {#for payout <- @payouts}
        <li class={
          "payout-row relative flex justify-between items-center gap-x-6 py-5 hover:bg-base-300 px-5",
          "bg-base-300": @payout_id == payout.public_id
        }>
          <div class="min-w-0">
            <div class="flex items-start gap-x-3">
              <p class="text-xl font-semibold leading-6 amount">
                <LivePatch
                  class="grow"
                  to={if @payout_id == payout.public_id do
                    ~p"/studios/#{@studio.handle}/payouts"
                  else
                    ~p"/studios/#{@studio.handle}/payouts/#{payout.public_id}"
                  end}
                >
                  <span class="absolute inset-x-0 -top-px bottom-0" />
                  {Payments.print_money(payout.amount)}
                </LivePatch>
              </p>
              <p class={
                "status bg-opacity-20 rounded-md whitespace-nowrap mt-0.5 px-1.5 py-0.5 text-xs font-medium ring-1 ring-inset",
                status_color(payout.status)
              }>
                {Payout.humanize_status(payout.status)}
              </p>
            </div>
            <div class="mt-1 flex items-center gap-x-2 text-xs leading-6">
              <p class="whitespace-nowrap">
                Requested <time dateTime={payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>{payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}</time>
              </p>
            </div>
          </div>
          <div>
            <span class="sr-only">View Payout</span>
            <Icon name="chevron-right" />
          </div>
        </li>
      {/for}
    </ul>
    """
  end
end
