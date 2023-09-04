defmodule BanchanWeb.SetupMfaLive do
  @moduledoc """
  Account Setup 2FA
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Form

  alias Banchan.Accounts

  alias BanchanWeb.AuthLive.Components.AuthLayout
  alias BanchanWeb.Components.Form.{Submit, TextInput}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user.totp_secret do
      secret = Base.encode32(user.totp_secret, padding: false)

      totp_svg =
        NimbleTOTP.otpauth_uri("Banchan:#{user.email}", user.totp_secret, issuer: "Banchan")
        |> EQRCode.encode()
        |> EQRCode.svg(width: 200, padding: "10px", background_color: "white")

      {:ok,
       socket |> assign(qrcode_svg: totp_svg, secret: secret, totp_activated: user.totp_activated)}
    else
      {:ok, socket |> assign(qrcode_svg: nil, secret: nil, totp_activated: false)}
    end
  end

  @impl true
  def handle_event("setup_mfa", _, socket) do
    user = socket.assigns.current_user

    if user.totp_activated == true do
      socket =
        socket
        |> put_flash(:info, "TOTP already activated")
        |> redirect(to: ~p"/2fa_setup")

      {:noreply, socket}
    end

    case Accounts.generate_totp_secret(user) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "2FA token generated successfully")
          |> redirect(to: ~p"/2fa_setup")

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("deactivate_mfa", %{"user" => u}, socket) do
    user = socket.assigns.current_user

    if user.totp_activated do
      case Accounts.deactivate_totp(user, u["password"]) do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(:info, "2FA token deactivated")
            |> push_navigate(to: ~p"/2fa_setup")

          {:noreply, socket}

        {:error, :invalid_password} ->
          socket =
            socket
            |> put_flash(:error, "Invalid password")
            |> push_navigate(to: ~p"/2fa_setup")

          {:noreply, socket}
      end
    else
      socket =
        socket
        |> put_flash(:error, "TOTP not activated")
        |> redirect(to: ~p"/2fa_setup")

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("confirm_mfa", val, socket) do
    user = socket.assigns.current_user

    if user.totp_activated do
      socket =
        socket
        |> put_flash(:info, "TOTP already activated")
        |> redirect(to: ~p"/2fa_setup")

      {:noreply, socket}
    end

    case Accounts.activate_totp(
           user,
           val["user"]["token"]
         ) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "2FA token activated")
          |> redirect(to: ~p"/2fa_setup")

        {:noreply, socket}

      {:error, :invalid_token} ->
        socket =
          socket
          |> put_flash(:error, "Invalid 2FA token")
          |> redirect(to: ~p"/2fa_setup")

        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <AuthLayout flashes={@flash}>
      {#if @qrcode_svg && !@totp_activated}
        <h1 class="text-2xl">Your QR Code</h1>
        <br>
        {raw(@qrcode_svg)}
        <br>
        No QR code reader? Input the following value in your 2FA app:
        <br>
        {@secret}
        <div class="divider" />
        <h1 class="text-2xl">Confirm 2FA 6-digit OTP</h1>
        <Form class="flex flex-col gap-4" for={%{}} as={:user} submit="confirm_mfa">
          <TextInput name={:token} label="One Time Password" opts={required: true} />
          <Submit class="w-full" label="Activate" />
        </Form>
      {#elseif @qrcode_svg && @totp_activated}
        <h1 class="text-2xl">You have 2FA enabled</h1>
        <Form for={%{}} as={:user} submit="deactivate_mfa">
          <TextInput name={:password} label="Current Password" opts={required: true, type: "password"} />
          <Submit class="w-full btn-error" label="Deactivate 2FA" />
        </Form>
      {#else}
        <h1 class="text-2xl">2FA Setup</h1>
        <Form for={%{}} as={:user} submit="setup_mfa">
          You do not have 2FA enabled.
          <Submit class="w-full" label="Set up 2FA" />
        </Form>
      {/if}
    </AuthLayout>
    """
  end
end
