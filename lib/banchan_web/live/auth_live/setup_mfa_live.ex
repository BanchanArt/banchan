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

    user = socket.assigns.current_user

    if user.totp_secret do
      totp_uri = NimbleTOTP.otpauth_uri("Banchan:#{user.email}", user.totp_secret, issuer: "Banchan")
      secret = Base.encode32(user.totp_secret, padding: false)
      totp_svg = totp_uri |> EQRCode.encode() |> EQRCode.svg(width: 200, color: "#000", background_color: "#FFF")

      {:ok, socket |> assign(qrcode_svg: totp_svg, secret: secret)}
    else
      {:ok, socket |> assign(qrcode_svg: nil, secret: nil)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <div class="shadow bg-base-200 text-base-content">
        {#if @qrcode_svg}
        <div class="p-6">
          <h1 class="text-2xl">Your QR Code</h1>
          <br />
          {raw(@qrcode_svg)}
          <br />
          No QR code reader? Input the following value in your MFA app:
          <br />
          {@secret}
        </div>
        {#else}
        <div class="p-6">
          <h1 class="text-2xl">MFA Setup</h1>
          <Form class="col-span-1" for={:user} submit="setup_mfa">
            <Submit label="Set up MFA" />
          </Form>
        </div>
        {/if}
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
