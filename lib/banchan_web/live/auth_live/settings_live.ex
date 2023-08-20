defmodule BanchanWeb.SettingsLive do
  @moduledoc """
  Account settings page
  """
  use BanchanWeb, :live_view

  alias Surface.Components.{Form, LiveRedirect}

  alias Banchan.Accounts
  alias Banchan.Accounts.InviteRequest
  alias Banchan.Notifications
  alias Banchan.Notifications.UserNotificationSettings

  alias BanchanWeb.AuthLive.Components.SettingsLayout
  alias BanchanWeb.Components.{Collapse, Icon}
  alias BanchanWeb.Components.Form.{Checkbox, EmailInput, Submit, TextArea, TextInput}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      settings =
        Notifications.get_notification_settings(socket.assigns.current_user) ||
          %UserNotificationSettings{commission_email: true, commission_web: true}

      if is_nil(socket.assigns.current_user.email) do
        {:ok,
         assign(socket,
           theme: nil,
           new_email_changeset: User.email_changeset(socket.assigns.current_user, %{}),
           handle_changeset: User.handle_changeset(socket.assigns.current_user, %{}),
           notification_settings: settings,
           notification_settings_changeset: UserNotificationSettings.changeset(settings, %{}),
           maturity_changeset: User.maturity_changeset(socket.assigns.current_user, %{}),
           muted_changeset: User.muted_changeset(socket.assigns.current_user, %{}),
           invite_request_changeset: InviteRequest.changeset(%InviteRequest{}, %{})
         )}
      else
        {:ok,
         assign(socket,
           theme: nil,
           handle_changeset: User.handle_changeset(socket.assigns.current_user, %{}),
           email_changeset: User.email_changeset(socket.assigns.current_user, %{}),
           password_changeset: User.password_changeset(socket.assigns.current_user, %{}),
           notification_settings: settings,
           notification_settings_changeset: UserNotificationSettings.changeset(settings, %{}),
           maturity_changeset: User.maturity_changeset(socket.assigns.current_user, %{}),
           muted_changeset: User.muted_changeset(socket.assigns.current_user, %{}),
           invite_request_changeset: InviteRequest.changeset(%InviteRequest{}, %{})
         )}
      end
    else
      {:ok, socket}
    end
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

  def handle_event("change_handle", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.handle_changeset(val["change_handle"])
      |> Map.put(:action, :update)

    socket = assign(socket, handle_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_handle", val, socket) do
    case Accounts.update_user_handle(
           socket.assigns.current_user,
           val["change_handle"]["password"],
           val["change_handle"]
         ) do
      {:ok, _updated_user} ->
        socket =
          socket
          |> put_flash(
            :info,
            "Your handle has been updated. Please log in again."
          )
          |> push_navigate(to: Routes.login_path(Endpoint, :new))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, handle_changeset: changeset)}
    end
  end

  def handle_event("change_new_email", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.email_changeset(val["new_email"])
      |> Map.put(:action, :update)

    socket = assign(socket, new_email_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_new_email", val, socket) do
    case Accounts.apply_new_user_email(
           socket.assigns.current_user,
           val["new_email"]
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

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, new_email_changeset: changeset)}

      {:error, :has_email} ->
        socket =
          socket
          |> put_flash(
            :error,
            "You already have an email address associated with your account."
          )

        {:noreply, socket}
    end
  end

  def handle_event("change_email", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.email_changeset(val["change_email"])
      |> Map.put(:action, :update)

    socket = assign(socket, email_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_email", val, socket) do
    case Accounts.apply_user_email(
           socket.assigns.current_user,
           val["change_email"]["password"],
           val["change_email"]
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

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, email_changeset: changeset)}
    end
  end

  @impl true
  def handle_event("change_password", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.password_changeset(val["change_password"])
      |> Map.put(:action, :update)

    socket = assign(socket, password_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_password", val, socket) do
    case Accounts.update_user_password(
           socket.assigns.current_user,
           val["change_password"]["current_password"],
           val["change_password"]
         ) do
      {:ok, _user} ->
        socket =
          socket
          |> put_flash(
            :info,
            "Password updated successfully"
          )

        {:noreply,
         push_navigate(socket,
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

  def handle_event("change_maturity", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.maturity_changeset(val["change_maturity"])
      |> Map.put(:action, :update)

    socket = assign(socket, maturity_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_maturity", val, socket) do
    case Accounts.update_maturity(
           socket.assigns.current_user,
           val["change_maturity"]
         ) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(
           current_user: updated_user,
           maturity_changeset: User.maturity_changeset(updated_user, %{})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, maturity_changeset: changeset)}
    end
  end

  def handle_event("change_muted", val, socket) do
    changeset =
      socket.assigns.current_user
      |> User.muted_changeset(val["change_muted"])
      |> Map.put(:action, :update)

    socket = assign(socket, muted_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_muted", val, socket) do
    case Accounts.update_muted(
           socket.assigns.current_user,
           val["change_muted"]
         ) do
      {:ok, updated_user} ->
        {:noreply,
         socket
         |> assign(
           current_user: updated_user,
           muted_changeset: User.muted_changeset(updated_user, %{})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, muted_changeset: changeset)}
    end
  end

  def handle_event("submit_deactivate", val, socket) do
    case Accounts.deactivate_user(
           socket.assigns.current_user,
           socket.assigns.current_user,
           val["deactivate"] && val["deactivate"]["password"]
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Your account has been deactivated."
         )
         |> redirect(to: Routes.home_path(Endpoint, :index))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Something went wrong. Please try again later.")}
    end
  end

  def handle_event("change_invite_request", val, socket) do
    changeset =
      %InviteRequest{}
      |> InviteRequest.changeset(val["change_invite_request"])
      |> Map.put(:action, :update)

    socket = assign(socket, invite_request_changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "submit_invite_request",
        %{"change_invite_request" => %{"email" => email}},
        socket
      ) do
    case Accounts.send_invite(
           socket.assigns.current_user,
           email,
           &Routes.artist_token_url(Endpoint, :confirm_artist, &1)
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "An invite has been sent to #{email}."
         )
         |> redirect(to: Routes.settings_path(Endpoint, :edit))}

      {:error, :no_invites} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "You have no invites left."
         )
         |> redirect(to: Routes.settings_path(Endpoint, :edit))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "An internal error occurred while trying to send your invite. Please try again later."
         )
         |> redirect(to: Routes.settings_path(Endpoint, :edit))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <SettingsLayout flashes={@flash}>
      <h1 class="mb-2 text-xl font-semibold">Account Settings</h1>
      <div class="divider" />
      <h2 class="mb-2 text-xl font-semibold">Appearance</h2>
      <div class="flex flex-row items-center gap-4 py-2">
        <label class="cursor-pointer label grow">
          <span>Color Mode</span>
          <label class="swap">
            <input
              :hook="Theme"
              id="toggle_theme"
              checked={@theme == "dark"}
              :on-click="toggle_theme"
              type="checkbox"
              class={"hidden", loading: !@theme}
            />
            <div class="swap-off">
              <Icon name="sun" size="6" label="light-mode" />
            </div>
            <div class="swap-on">
              <Icon name="moon-star" size="6" label="dark-mode" />
            </div>
          </label>
        </label>
      </div>
      <div class="divider" />
      <h2 class="mb-2 text-xl font-semibold">
        Notifications
      </h2>
      <Form
        class="flex flex-col max-w-xl gap-4"
        for={@notification_settings_changeset}
        change="change_notification_settings"
        submit="submit_notification_settings"
      >
        <h3 class="mb-2 text-lg">Commissions</h3>
        <Checkbox name={:commission_email} label="Email" />
        <Checkbox name={:commission_web} label="Web" />
        <Submit class="w-fit" changeset={@notification_settings_changeset} label="Save" />
      </Form>
      <div class="divider" />
      <Form
        class="flex flex-col max-w-xl gap-4"
        as={:change_handle}
        for={@handle_changeset}
        change="change_handle"
        submit="submit_handle"
        opts={autocomplete: "off"}
      >
        <h3 class="mb-2 text-xl font-semibold">
          Update Handle
        </h3>
        <TextInput name={:handle} icon="at-sign" opts={required: true, placeholder: "example123"} />
        {#if @current_user.email}
          <TextInput
            name={:password}
            icon="lock"
            opts={required: true, type: :password, placeholder: "your_password"}
          />
          <LiveRedirect class="link link-primary" to={Routes.forgot_password_path(Endpoint, :edit)}>
            Forgot your password?
          </LiveRedirect>
        {/if}
        <Submit class="w-fit" changeset={@handle_changeset} label="Save" />
      </Form>
      <div class="divider" />
      {#if is_nil(@current_user.email)}
        <Form
          class="flex flex-col max-w-xl gap-4"
          as={:new_email}
          for={@new_email_changeset}
          change="change_new_email"
          submit="submit_new_email"
          opts={autocomplete: "off"}
        >
          <h3 class="mb-2 text-lg">Set Your Email</h3>
          <div>
            You created this account through third-party authentication that did not provide an email address. If you want to be able to log in with an email and password, or change your <code>@handle</code>, please provide an email and we will send you a password reset.
          </div>
          <EmailInput
            name={:email}
            icon="mail"
            opts={required: true, placeholder: "youremail@example.com"}
          />
          <Submit class="w-fit" changeset={@new_email_changeset} label="Save" />
        </Form>
      {#else}
        <div class="flex flex-col max-w-xl gap-4">
          <h3 class="mb-2 text-xl font-semibold">Two-factor Authentication</h3>
          <p class="py-2">2FA helps secure your account by requiring an additional device to log in. Banchan supports any standard OTP application, such as Google Authenticator, Authy, or 1Password.</p>
          <LiveRedirect class="w-fit btn btn-primary" to={Routes.setup_mfa_path(Endpoint, :edit)}>Manage 2FA</LiveRedirect>
        </div>
        <div class="divider" />
        <Form
          class="flex flex-col max-w-xl gap-4"
          as={:change_email}
          for={@email_changeset}
          change="change_email"
          submit="submit_email"
          opts={autocomplete: "off"}
        >
          <h3 class="mb-2 text-lg">
            Update Email
          </h3>
          <EmailInput
            name={:email}
            icon="mail"
            opts={required: true, placeholder: "youremail@example.com"}
          />
          <TextInput
            name={:password}
            icon="lock"
            opts={required: true, type: :password, placeholder: "your_password"}
          />
          <LiveRedirect class="link link-primary" to={Routes.forgot_password_path(Endpoint, :edit)}>
            Forgot your password?
          </LiveRedirect>
          <Submit class="w-fit" changeset={@email_changeset} label="Save" />
        </Form>
        <div class="divider" />
        <Form
          class="flex flex-col max-w-xl gap-4"
          as={:change_password}
          for={@password_changeset}
          change="change_password"
          submit="submit_password"
          opts={autocomplete: "off"}
        >
          <h3 class="mb-2 text-lg">
            Update Password
          </h3>
          <TextInput
            name={:current_password}
            icon="lock"
            label="Current Password"
            opts={required: true, type: :password, placeholder: "your_old_password"}
          />
          <TextInput
            name={:password}
            label="New Password"
            icon="lock"
            opts={required: true, type: :password, placeholder: "your_new_secure_password"}
          />
          <TextInput
            name={:password_confirmation}
            icon="lock"
            label="New Password Confirmation"
            opts={required: true, type: :password, placeholder: "your_new_secure_password"}
          />
          <LiveRedirect class="link link-primary" to={Routes.forgot_password_path(Endpoint, :edit)}>
            Forgot your password?
          </LiveRedirect>
          <Submit class="w-fit" changeset={@password_changeset} label="Save" />
        </Form>
      {/if}
      {#if Accounts.mod?(@current_user) || @current_user.available_invites > 0}
        <div class="divider" />
        <Form
          class="flex flex-col max-w-xl gap-4"
          for={@invite_request_changeset}
          as={:change_invite_request}
          change="change_invite_request"
          submit="submit_invite_request"
        >
          <h3 class="mb-2 text-xl font-semibold">Send an Artist Invite</h3>
          <p :if={!Accounts.mod?(@current_user)}>You have {@current_user.available_invites} invite(s) available.</p>
          <EmailInput
            name={:email}
            icon="mail"
            opts={required: true, placeholder: "youremail@example.com"}
          />
          <Submit class="w-fit" changeset={@invite_request_changeset} label="Send" />
        </Form>
      {/if}
      <div class="divider" />
      <Form
        class="flex flex-col max-w-xl gap-4"
        for={@muted_changeset}
        as={:change_muted}
        change="change_muted"
        submit="submit_muted"
      >
        <h3 class="mb-2 text-xl font-semibold">Muted Words</h3>
        <p>Words here will be used to filter out content that appears in the homepage and in discovery searches.</p>
        <TextArea name={:muted} info="Enter your desired muted words" label="Muted Words" />
        <Submit class="w-fit" changeset={@muted_changeset} label="Save" />
      </Form>
      <div class="divider" />
      {#if Application.get_env(:banchan, :mature_content_enabled?)}
        <Form
          class="flex flex-col max-w-xl gap-4"
          for={@maturity_changeset}
          as={:change_maturity}
          change="change_maturity"
          submit="submit_maturity"
        >
          <h3 class="mb-2 text-xl font-semibold">Mature Content</h3>
          <p>By choosing to display mature content on the site, you assert that you are legally an adult in your country and able to view this content.</p>
          <Checkbox
            name={:mature_ok}
            info="Whether to show mature content items (studios, offerings, etc) at all."
            label="List Mature Content"
          />
          <Checkbox
            name={:uncensored_mature}
            info="Whether to show mature content uncensored. By default, you need to click through to view mature content you come aross."
            label="Uncensor Mature Content by Default"
          />
          <Submit class="w-fit" changeset={@maturity_changeset} label="Save" />
        </Form>
        <div class="divider" />
      {/if}
      <h3 class="mb-2 text-xl font-semibold">Deactivate Account ⚠️</h3>
      <div class="prose">
        <p>You can deactivate your account. Existing commissions (and their comments), uploads, studios, etc. will be retained, but with your account anonymized, and your user profile will be disabled.</p>
        <p>If you want your studios to be deleted as well, <strong>you must do that before  deactivating</strong>.  Otherwise, they'll just stick around forever.</p>
        <p>You can reverse this decision and reactivate your account at any time in the next 30 days. After 30 days, your account will be permanently deleted and you will no longer be able to access it or recover it.</p>
      </div>
      <Collapse id="deactivate-account-collapse" class="w-full pt-4">
        <:header>
          <div class="py-4 text-error">Deactivate</div>
        </:header>
        <Form class="flex flex-col max-w-xl gap-4" for={%{}} as={:deactivate} submit="submit_deactivate">
          <p>
            You will have 30 days to change your mind.
          </p>
          <p class="py-2">Are you sure?</p>

          {#if !Accounts.oauth_user?(@current_user)}
            <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
          {/if}
          <Submit class="w-fit btn-error" label="Confirm" />
        </Form>
      </Collapse>
    </SettingsLayout>
    """
  end
end
