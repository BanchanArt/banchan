defmodule BanchanWeb.SettingsLive do
  @moduledoc """
  Account settings page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts
  alias Banchan.Notifications
  alias Banchan.Notifications.UserNotificationSettings

  alias BanchanWeb.AuthLive.Components.AuthLayout
  alias BanchanWeb.Components.Form.{Checkbox, EmailInput, Submit, TextInput}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      settings =
        Notifications.get_notification_settings(socket.assigns.current_user) ||
          %UserNotificationSettings{commission_email: true, commission_web: true}

      {:ok,
       assign(socket,
         theme: nil,
         email_changeset: User.email_changeset(socket.assigns.current_user, %{}),
         password_changeset: User.password_changeset(socket.assigns.current_user, %{}),
         notification_settings: settings,
         notification_settings_changeset: UserNotificationSettings.changeset(settings, %{})
       )}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("toggle_theme", val, socket) do
    {:noreply,
     socket
     |> push_event("set_theme", %{
       theme:
         if val["value"] do
           "dark"
         else
           "light"
         end
     })}
  end

  @impl true
  def handle_event("theme_changed", %{"theme" => theme}, socket) do
    {:noreply, socket |> assign(theme: theme)}
  end

  def handle_event("change_email", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.email_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, email_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_email", val, socket) do
    case Accounts.apply_user_email(
           socket.assigns.current_user,
           val["user"]["password"],
           val["user"]
         ) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          socket.assigns.current_user.email,
          &Routes.user_settings_url(Endpoint, :confirm_email, &1)
        )

        socket =
          socket
          |> put_flash(
            :info,
            "A link to confirm your email change has been sent to the new address."
          )

        {:noreply, socket}

      other ->
        other
    end
  end

  @impl true
  def handle_event("change_password", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.password_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, password_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_password", val, socket) do
    case Accounts.update_user_password(
           socket.assigns.current_user,
           val["user"]["current_password"],
           val["user"]
         ) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(
            :info,
            "Password updated successfully"
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

      {:error, changeset} ->
        {:noreply, assign(socket, password_changeset: changeset)}
    end
  end

  @impl true
  def handle_event("change_notification_settings", val, socket) do
    changeset =
      socket.assigns.notification_settings
      |> UserNotificationSettings.changeset(val["user_notification_settings"])
      |> Map.put(:action, :update)

    socket = assign(socket, notification_settings_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_notification_settings", val, socket) do
    case Notifications.update_user_notification_settings(
           socket.assigns.current_user,
           val["user_notification_settings"]
         ) do
      {:ok, settings} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Notification settings updated successfully."
         )
         |> assign(
           notification_settings: settings,
           notification_settings_changeset: UserNotificationSettings.changeset(settings, %{})
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, notification_settings_changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <AuthLayout uri={@uri} current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Account Settings</h1>
      <div class="divider" />
      <h2 class="text-xl">Appearance</h2>
      <div class="flex flex-row items-center py-6 gap-4">
        <span>Dark Mode</span>
        <input
          :hook="Theme"
          id="toggle_theme"
          checked={@theme == "dark"}
          :on-click="toggle_theme"
          type="checkbox"
          class={"toggle", loading: !@theme}
        />
      </div>
      <div class="divider" />
      <h2 class="text-xl">
        Notifications
      </h2>
      <Form
        class="flex flex-col gap-4"
        for={@notification_settings_changeset}
        change="change_notification_settings"
        submit="submit_notification_settings"
      >
        <h3 class="text-lg">Commissions</h3>
        <Checkbox name={:commission_email} label="Email" />
        <Checkbox name={:commission_web} label="Web" />
        <Submit class="w-full" changeset={@notification_settings_changeset} label="Save" />
      </Form>
      <div class="divider" />
      <Form
        class="flex flex-col gap-4"
        for={@email_changeset}
        change="change_email"
        submit="submit_email"
        opts={autocomplete: "off"}
      >
        <h3 class="text-lg font-medium">
          Update Email
        </h3>
        <EmailInput name={:email} icon="envelope" opts={required: true} />
        <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
        <Submit class="w-full" changeset={@email_changeset} label="Save" />
      </Form>
      <div class="divider" />
      <Form
        class="flex flex-col gap-4"
        for={@password_changeset}
        change="change_password"
        submit="submit_password"
        opts={autocomplete: "off"}
      >
        <h3 class="text-lg">
          Update Password
        </h3>
        <TextInput
          name={:current_confirmation}
          icon="lock"
          label="Current Password"
          opts={required: true, type: :password}
        />
        <TextInput
          name={:password}
          label="New Password"
          icon="lock"
          opts={required: true, type: :password}
        />
        <TextInput
          name={:password_confirmation}
          icon="lock"
          label="New Password Confirmation"
          opts={required: true, type: :password}
        />
        <Submit class="w-full" changeset={@password_changeset} label="Save" />
      </Form>
    </AuthLayout>
    """
  end
end
