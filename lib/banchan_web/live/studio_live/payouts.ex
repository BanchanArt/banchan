defmodule BanchanWeb.StudioLive.Payouts do
  @moduledoc """
  Studio payouts page.
  """
  use BanchanWeb, :surface_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Studios

  alias BanchanWeb.CommissionLive.Components.StudioLayout
  alias BanchanWeb.Components.Button

  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    {:ok,
     socket
     |> assign(balance: Studios.get_stripe_balance!(socket.assigns.studio))}
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
     |> assign(balance: Studios.get_stripe_balance!(socket.assigns.studio))}
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
              Ready for Payout
            </div>
            <div class="stat-value">
              {Enum.join(
                Enum.map(
                  @balance.available,
                  &Money.to_string(Money.new(&1.amount, String.to_existing_atom(String.upcase(&1.currency))))
                ),
                " + "
              )}
            </div>
            <div class="stat-actions">
              <Button click="pay_me">Pay Me Now</Button>
            </div>
          </div>
          <div class="stat">
            <div class="stat-title">
              Pending
            </div>
            <div class="stat-value">
              {Enum.join(
                Enum.map(
                  @balance.pending,
                  &Money.to_string(Money.new(&1.amount, String.to_existing_atom(String.upcase(&1.currency))))
                ),
                " + "
              )}
            </div>
            <div class="stat-actions">
              <Button>Stripe Dashboard</Button>
            </div>
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
