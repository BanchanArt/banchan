defmodule BanchanWeb.SetupMfaLive do
  @moduledoc """
  Account Setup MFA
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts

  alias BanchanWeb.Components.Form.{Submit}
  alias BanchanWeb.Components.Layout

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <div class="shadow bg-base-200 text-base-content">
        <div class="p-6">
          <h1 class="text-2xl">MFA Setup</h1>
          <Form class="col-span-1" for={:user} submit="setup_mfa">
            <Submit label="Set up MFA" />
          </Form>
        </div>
      </div>
    </Layout>
    """
  end

  @impl true
  def handle_event("setup_mfa", _, socket) do
    user = socket.assigns.current_user
    if user.totp_activated == true do
      socket
        |> put_flash(
          :info,
          "TOTP already activated"
        )
    end

    case Accounts.generate_totp_secret(
      user
      ) do
    {:ok, user} ->
      socket =
        socket
        |> put_flash(
          :info,
          "MFA token generated successfully, #{user.totp_secret}"
        )

      {:noreply,
        push_redirect(socket,
          to:
            Routes.user_session_path(
              Endpoint,
              :refresh_session,
              Routes.settings_path(Endpoint, :edit)
            )
        )}
    end
  end
end
