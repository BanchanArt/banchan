defmodule BanchanWeb.StudioLive.Payouts do
  @moduledoc """
  Studio payouts page.
  """
  use BanchanWeb, :surface_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Studios

  alias BanchanWeb.Components.Button
  alias BanchanWeb.StudioLive.Components.StudioLayout

  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, true)

    if socket.redirected do
      {:ok, socket}
    else
      {:ok,
       socket
       |> assign(balance: Studios.get_banchan_balance!(socket.assigns.studio))}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
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
      <div class="mx-auto">
        <h2 class="text-xl">Available for Payout</h2>
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
        </div>

        <h2 class="text-xl">Waiting for Approval</h2>
        <div id="held-back" class="stats stats-horizontal">
          {#for held <- @balance.held_back}
            <div class="stat">
              <div class="stat-value">{Money.to_string(held)}</div>
            </div>
          {#else}
            <div class="stat">
              <div class="stat-value">{Money.to_string(Money.new(0, :USD))}</div>
            </div>
          {/for}
        </div>

        <h2 class="text-xl">On the Way</h2>
        <div id="on-the-way" class="stats stats-horizontal">
          {#for otw <- @balance.on_the_way}
            <div class="stat">
              <div class="stat-value">{Money.to_string(otw)}</div>
            </div>
          {#else}
            <div class="stat">
              <div class="stat-value">{Money.to_string(Money.new(0, :USD))}</div>
            </div>
          {/for}
        </div>
      </div>
    </StudioLayout>
    """
  end
end
