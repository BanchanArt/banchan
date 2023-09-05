defmodule BanchanWeb.SetupMfaLive do
  @moduledoc """
  Account Setup MFA
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
        |> redirect(to: Routes.setup_mfa_path(socket, :edit))

      {:noreply, socket}
    end

    case Accounts.generate_totp_secret(user) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "MFA token generated successfully")
          |> redirect(to: Routes.setup_mfa_path(socket, :edit))

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
            |> put_flash(:info, "MFA token deactivated")
            |> push_navigate(to: Routes.setup_mfa_path(socket, :edit))

          {:noreply, socket}

        {:error, :invalid_password} ->
          socket =
            socket
            |> put_flash(:error, "Invalid password")
            |> push_navigate(to: Routes.setup_mfa_path(socket, :edit))

          {:noreply, socket}
      end
    else
      socket =
        socket
        |> put_flash(:error, "TOTP not activated")
        |> redirect(to: Routes.setup_mfa_path(socket, :edit))

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
        |> redirect(to: Routes.setup_mfa_path(socket, :edit))

      {:noreply, socket}
    end

    case Accounts.activate_totp(
           user,
           val["user"]["token"]
         ) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "MFA token activated")
          |> redirect(to: Routes.setup_mfa_path(socket, :edit))

        {:noreply, socket}

      {:error, :invalid_token} ->
        socket =
          socket
          |> put_flash(:error, "Invalid MFA token")
          |> redirect(to: Routes.setup_mfa_path(socket, :edit))

        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <AuthLayout flashes={@flash}>
      {#if @qrcode_svg && !@totp_activated}
        <div class="grid grid-cols-1 gap-2">
          <h1 class="text-2xl">Your QR Code</h1>
          <span class="text-sm opacity-75">Scan the QR code below with your MFA app.</span>
          <div class="py-4">{raw(@qrcode_svg)}</div>
          <span>No QR code reader?</span>
          <span class="text-sm opacity-75">
            Input the following value in your MFA app:
          </span>
          <div class="flex flex-row items-center input">
            <span class="font-mono tracking-wide">
              {@secret}
            </span>
          </div>
          <div class="divider" />
          <h1 class="text-2xl">Confirm MFA 6-digit OTP</h1>
          <Form class="flex flex-col gap-4" for={%{}} as={:user} submit="confirm_mfa">
            <TextInput name={:token} label="One Time Password" opts={required: true} />
            <Submit class="w-full" label="Activate" />
          </Form>
        </div>
      {#elseif @qrcode_svg && @totp_activated}
        <div class="grid grid-cols-1 gap-2">
          <h1 class="text-2xl">You have MFA enabled</h1>
          <Form for={%{}} as={:user} submit="deactivate_mfa">
            <TextInput name={:password} label="Current Password" opts={required: true, type: "password"} />
            <Submit class="w-full btn-error" label="Deactivate MFA" />
          </Form>
        </div>
      {#else}
        <div class="grid grid-cols-1 gap-2">
          <h1 class="text-2xl">MFA Setup</h1>
          <Form for={%{}} as={:user} submit="setup_mfa" class="grid grid-cols-1 gap-2">
            <span class="opacity-75">Set up MFA to protect your account and add an extra layer of security.</span>
            <Submit class="w-full" label="Set up MFA" />
          </Form>
        </div>
      {/if}
    </AuthLayout>
    """
  end
end
