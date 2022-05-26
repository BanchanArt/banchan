defmodule BanchanWeb.SettingsLive do
  @moduledoc """
  Account settings page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts
  alias Banchan.Notifications
  alias Banchan.Notifications.UserNotificationSettings

  alias BanchanWeb.Components.Form.{Checkbox, EmailInput, Submit, TextInput}
  alias BanchanWeb.Components.Layout
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
       theme: if val["value"] do
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
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <div class="shadow bg-base-200 text-base-content">
        <div class="p-6">
          <h1 class="text-2xl">Account Settings</h1>
          <br>
          <h2 class="text-xl">Appearance</h2>
          <div class="flex flex-row items-center gap-4">
            <span>Dark Mode</span>
            <input
              :hook="Theme"
              id="toggle_theme"
              checked={@theme == "dark"}
              :on-click="toggle_theme"
              type="checkbox"
              class="toggle"
            />
            {#if !@theme}
              <svg
                class="animate-spin -ml-1 mr-3 h-5 w-5 text-white"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
              >
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path
                  class="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
            {/if}
          </div>

          <div
            tabindex="0"
            class="collapse w-96 border rounded-box border-base-300 collapse-arrow collapse-open"
          >
            <div class="collapse-title text-xl font-medium">
              Notifications
            </div>
            <div class="collapse-content">
              <Form
                class="col-span-auto"
                for={@notification_settings_changeset}
                change="change_notification_settings"
                submit="submit_notification_settings"
              >
                <h2 class="text-lg">Commissions</h2>
                <Checkbox name={:commission_email} label="Email" />
                <Checkbox name={:commission_web} label="Web" />
                <Submit changeset={@notification_settings_changeset} label="Save" />
              </Form>
            </div>
          </div>
          <div
            tabindex="0"
            class="collapse w-96 border rounded-box border-base-300 collapse-arrow collapse-open"
          >
            <div class="collapse-title text-xl font-medium">
              Update Email
            </div>
            <div class="collapse-content">
              <Form
                class="col-span-auto"
                for={@email_changeset}
                change="change_email"
                submit="submit_email"
                opts={autocomplete: "off"}
              >
                <EmailInput name={:email} icon="envelope" opts={required: true} />
                <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
                <Submit changeset={@email_changeset} label="Save" />
              </Form>
            </div>
          </div>
          <div
            tabindex="0"
            class="collapse w-96 border rounded-box border-base-300 collapse-arrow collapse-open"
          >
            <div class="collapse-title text-xl font-medium">
              Update Password
            </div>
            <div class="collapse-content">
              <Form
                class="col-span-auto"
                for={@password_changeset}
                change="change_password"
                submit="submit_password"
                opts={autocomplete: "off"}
              >
                <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
                <TextInput
                  name={:password_confirmation}
                  icon="lock"
                  label="New Password Confirmation"
                  opts={required: true, type: :password}
                />
                <TextInput
                  name={:current_confirmation}
                  icon="lock"
                  label="New Password Confirmation"
                  opts={required: true, type: :password}
                />
                <Submit changeset={@password_changeset} label="Save" />
              </Form>
            </div>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
