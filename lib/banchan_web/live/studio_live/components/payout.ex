defmodule BanchanWeb.StudioLive.Components.Payout do
  @moduledoc """
  Individual Payout display component. Shows a list of invoices related to
  commissions that were paid out as part of this Payout.
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  prop studio, :struct, required: true
  prop payout, :struct, required: true
  prop cancel_payout, :event, required: true

  def render(assigns) do
    ~F"""
    <div>
      <h1 class="flex flex-row text-3xl pt-4 px-4">
        <LivePatch
          class="md:hidden p-2"
          to={Routes.studio_payouts_path(Endpoint, :index, @studio.handle)}
        >
          <i class="fas fa-arrow-left text-2xl" />
        </LivePatch>
        <div class="flex flex-col">
          Payout - {Money.to_string(@payout.amount)}
          <h3
            class="text-xl"
            title={@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}
          >
            Requested {@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}
          </h3>
        </div>
      </h1>
      <ul class="text-md pt-4 px-4">
        <li>Invoice1</li>
        <li>Invoice2</li>
      </ul>
    </div>
    """
  end
end
