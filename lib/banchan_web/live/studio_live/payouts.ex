defmodule BanchanWeb.StudioLive.Payouts do
  @moduledoc """
  Studio payouts page.
  """
  use BanchanWeb, :surface_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Studios

  alias BanchanWeb.CommissionLive.Components.StudioLayout

  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    {:ok,
     socket
     |> assign(balance: Studios.get_banchan_balance!(socket.assigns.studio))}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("pay_me", _, socket) do
    Studios.payout_studio!(socket.assigns.studio)

    {:noreply,
     socket
     |> assign(balance: Studios.get_banchan_balance!(socket.assigns.studio))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:settings}
      uri={@uri}
    >
      <div class="mx-auto">
        <div class="stats">
          <div class="stat">
            <div class="stat-title">
              Released from Commissions
            </div>
            <div class="stat-value">
              {Enum.join(
                Enum.map(
                  @balance.released,
                  &Money.to_string(Money.subtract(Money.add(&1.charged, &1.tips), &1.fees))
                ),
                " + "
              )}
            </div>
            <div class="stat-desc">
              Approved for release by clients.
            </div>
          </div>
          <div class="stat">
            <div class="stat-title">
              Held by Banchan
            </div>
            <div class="stat-value">
              {Enum.join(
                Enum.map(
                  @balance.held_back,
                  &Money.to_string(Money.subtract(Money.add(&1.charged, &1.tips), &1.fees))
                ),
                " + "
              )}
            </div>
            <div class="stat-desc">
              Paid into Banchan but not released.
            </div>
          </div>
          <div class="stat">
            <div class="stat-title">
              Pending on Stripe
            </div>
            <div class="stat-value">
              {Enum.join(
                Enum.map(
                  @balance.stripe_pending,
                  &Money.to_string(&1)
                ),
                " + "
              )}
            </div>
            <div class="stat-desc">
              Waiting for Stripe availability.
            </div>
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
