defmodule BanchanWeb.StudioLive.Payouts do
  @moduledoc """
  Studio payouts page.
  """
  use BanchanWeb, :surface_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Studios

  alias BanchanWeb.Components.Button
  alias BanchanWeb.StudioLive.Components.{Payout, PayoutRow, StudioLayout}

  def mount(params, _session, socket) do
    {:ok, assign_studio_defaults(params, socket, true, true)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    if socket.redirected do
      {:noreply, socket}
    else
      payout =
        case params do
          %{"payout_id" => payout_id} ->
            # NOTE: Phoenix LiveView's push_patch has an obnoxious bug with fragments, so
            # we have to manually remove them here.
            # See: https://github.com/phoenixframework/phoenix_live_view/issues/2041
            payout_id = Regex.replace(~r/#.*$/, payout_id, "")
            Studios.get_payout!(payout_id)

          _ ->
            nil
        end

      {:noreply,
       socket
       |> assign(uri: uri)
       |> assign(payout: payout)
       |> assign(results: Studios.list_payouts(socket.assigns.studio, page(params)))
       |> assign(balance: Studios.get_banchan_balance!(socket.assigns.studio))}
    end
  end

  @impl true
  def handle_event("fypm", _, socket) do
    case Studios.payout_studio(socket.assigns.studio) do
      {:ok, _payouts} ->
        {:noreply,
         socket
         |> put_flash(
           :success,
           "Payouts sent! It may be a few days before they arrive in your account."
         )
         |> assign(balance: Studios.get_banchan_balance!(socket.assigns.studio))}

      {:error, user_msg} ->
        {:noreply,
         socket
         |> put_flash(:error, user_msg)
         |> assign(balance: Studios.get_banchan_balance!(socket.assigns.studio))}
    end
  end

  defp payout_possible?(available) do
    !Enum.empty?(available) &&
      Enum.all?(available, &(&1.amount > 0))
  end

  defp page(%{"page" => page}) do
    case Integer.parse(page) do
      {p, ""} ->
        p

      _ ->
        1
    end
  end

  defp page(_other) do
    1
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:payouts}
      uri={@uri}
    >
      <div class="flex flex-col grow max-h-full">
        <div class="flex flex-row grow md:grow-0">
          <div class={"flex flex-col grow md:grow-0 md:basis-1/4", "hidden md:flex": @payout}>
            <div id="available" class="flex flex-col">
              <div class="stats stats-horizontal">
                {#for avail <- @balance.available}
                  {#if avail.amount > 0}
                    <div class="stat">
                      <div class="stat-value">{Money.to_string(avail)}</div>
                    </div>
                  {/if}
                {/for}
                {#if !payout_possible?(@balance.available)}
                  <div class="stat">
                    <div class="stat-value">{Money.to_string(Money.new(0, :USD))}</div>
                  </div>
                {/if}
              </div>
              <Button click="fypm" disabled={!payout_possible?(@balance.available)}>Pay Out</Button>
              <div class="divider" />
              <ul class="divide-y flex-grow flex flex-col">
                {#for payout <- @results.entries}
                  <li>
                    <PayoutRow
                      studio={@studio}
                      payout={payout}
                      highlight={@payout && @payout.public_id == payout.public_id}
                    />
                  </li>
                {/for}
              </ul>
            </div>
          </div>
          <div class="md:container md:basis-3/4">
            {#if @payout}
              <Payout studio={@studio} payout={@payout} cancel_payout="cancel_payout" />
            {/if}
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
