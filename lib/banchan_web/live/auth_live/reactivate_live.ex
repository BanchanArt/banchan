defmodule BanchanWeb.ReactivateLive do
  @moduledoc """
  Account reactivation page.
  """
  use BanchanWeb, :live_view

  alias Banchan.Accounts

  alias BanchanWeb.AuthLive.Components.AuthLayout
  alias BanchanWeb.Components.Button

  @impl true
  def handle_event("reactivate", _, socket) do
    case Accounts.reactivate_user(socket.assigns.current_user, socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Your account has been reactivated. Welcome back!")
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong. Please try again later.")}
    end
  end

  @impl true
  def render(assigns) do
    days =
      case Accounts.days_until_deletion(assigns.current_user) do
        1 ->
          "1 day"

        n ->
          "#{n} days"
      end

    ~F"""
    <AuthLayout flashes={@flash}>
      <h1 class="text-2xl mx-auto">Reactivate Your Account</h1>
      <p>Your account is currently deactivated and will be fully deleted in {days}.</p>
      <Button click="reactivate" class="w-full" label="Reactivate" />
    </AuthLayout>
    """
  end
end
