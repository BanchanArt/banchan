defmodule BanchanWeb.StudioLive.Components.Payout do
  @moduledoc """
  Individual Payout display component. Shows a list of invoices related to
  commissions that were paid out as part of this Payout.
  """
  use BanchanWeb, :component

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias Banchan.Studios.Payout

  alias BanchanWeb.Components.{Avatar, Button, UserHandle}

  prop studio, :struct, required: true
  prop payout, :struct, required: true
  prop cancel_pending, :boolean, default: false
  prop cancel_payout, :event, required: true

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

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
        <div class="flex flex-row">
          <div>Payout - {Money.to_string(@payout.amount)}</div>
          <div class="badge badge-secondary badge-md">{Payout.humanize_status(@payout.status)}</div>
        </div>
      </h1>
      <div class="divider" />
      <h3
        class="px-4 text-md"
        title={@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}
      >
        <div class="inline">
          <div class="self-center inline">
            Initiated by
          </div>
          <div class="self-center inline">
            <Avatar user={@payout.actor} class="w-4" />
          </div>
          <div class="inline">
            <UserHandle user={@payout.actor} />
          </div>
        </div>
        {@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}.
      </h3>
      <div class="px-4">
        <div title={@payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>Expected arrival: {@payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}.</div>
        <div>Method: {@payout.method}</div>
        <div>Type: {@payout.type}</div>
        {#if @payout.failure_code}
          <div>Failure: {@payout.failure_message}</div>
        {/if}
        <Button
          class="cancel-payout"
          click={@cancel_payout}
          disabled={@cancel_pending || !@payout.stripe_payout_id || Payout.done?(@payout)}
        >
          {#if @cancel_pending}
            <i class="px-2 fas fa-spinner animate-spin" />
          {/if}
          Cancel
        </Button>
      </div>
      <ul class="text-md pt-4 px-4 list-disc">
        {#for invoice <- @payout.invoices}
          <li>
            {!-- NOTE: Using an href here because apparently LiveRedirect isn't properly moving to the anchor. Probably the delay in commission loading?? --}
            <a href={replace_fragment(
              Routes.commission_path(Endpoint, :show, invoice.commission.public_id),
              invoice.event
            )}>Invoice (link)</a>:
            Amount: {Money.to_string(invoice.amount)}, Tip: {Money.to_string(invoice.tip)}, Platform Fees: {Money.to_string(invoice.platform_fee)}, Net: {invoice.amount |> Money.add(invoice.tip) |> Money.subtract(invoice.platform_fee)}, <LiveRedirect to={Routes.commission_path(Endpoint, :show, invoice.commission.public_id)}>Commission (link)</LiveRedirect>
          </li>
        {/for}
      </ul>
    </div>
    """
  end
end
