defmodule BanchanWeb.StudioLive.Components.PayoutRow do
  @moduledoc """
  Row for displaying individual payouts for a Studio.
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  alias Banchan.Studios.Payout

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
    <div class={"bg-base-200": @highlight}>
      <LivePatch to={payout_url}>
        <div class="py-2 px-4">
          <div class="text-xl">
            {Money.to_string(@payout.amount)}
            <div class="badge badge-secondary badge-sm">{Payout.humanize_status(@payout.status)}</div>
          </div>
          <div
            class="text-xs text-left"
            title={@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}
          >
            {@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}
          </div>
        </div>
      </LivePatch>
    </div>
    """
  end
end
