defmodule BanchanWeb.SettingsLive do
  @moduledoc """
  Account settings page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts

  alias BanchanWeb.Components.Form.{EmailInput, Submit, TextInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    if socket.assigns.current_user do
      {:ok,
       assign(socket,
         email_changeset: User.email_changeset(socket.assigns.current_user, %{}),
         password_changeset: User.password_changeset(socket.assigns.current_user, %{})
       )}
    else
      {:ok, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <div class="shadow bg-base-200 text-base-content">
        <div class="p-6">
          <h1 class="text-2xl">Account Settings</h1>
          <br>
          <h2 class="text-xl">Appearance</h2>
          <div class="flex flex-row items-center gap-4">
            <span>Dark Mode:</span>
            <input :hook="Theme" id="theme_toggle" :on-click="toggle_theme" type="checkbox" class="toggle">
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

  @impl true
  def handle_event("toggle_theme", _, socket) do
    {:noreply, socket |> push_event("toggle_theme", %{change_theme: true})}
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
end
