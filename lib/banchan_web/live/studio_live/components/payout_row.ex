defmodule BanchanWeb.StudioLive.Components.PayoutRow do
  @moduledoc """
  Row for displaying individual payouts for a Studio.
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  alias Banchan.Payments.Payout

  prop studio, :struct, required: true
  prop payout, :struct, required: true
  prop highlight, :boolean, default: false

  def render(assigns) do
    payout_url =
      Routes.studio_payouts_path(
        Endpoint,
        :show,
        assigns.studio.handle,
        assigns.payout.public_id
      )

    ~F"""
    <li class={"payout-row", bordered: @highlight}>
      <LivePatch class="grow" to={payout_url}>
        <div>
          <div class="amount text-xl flex flex-col">
            <span>{Money.to_string(@payout.amount)}</span>
            <div class="badge badge-primary badge-sm cursor-default">{Payout.humanize_status(@payout.status)}</div>
          </div>
          <div
            class="text-xs text-left"
            title={@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}
          >
            {@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}
          </div>
        </div>
      </LivePatch>
    </li>
    """
  end
end
