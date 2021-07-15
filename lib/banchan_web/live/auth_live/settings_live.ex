defmodule BanchanWeb.SettingsLive do
  @moduledoc """
  Account settings page
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Surface.Components.Form.{
    EmailInput,
    ErrorTag,
    Field,
    Label,
    PasswordInput,
    Submit,
    TextInput
  }

  alias Banchan.Accounts
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)

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
      <h1 class="title">Account Settings</h1>
      <h2 class="subtitle">Update Email</h2>
      <Form
        for={@email_changeset}
        change="change_email"
        submit="submit_email"
        opts={autocomplete: "off"}
      >
        <Field name={:email}>
          <Label />
          <EmailInput />
          <ErrorTag />
        </Field>
        <Field name={:password}>
          <Label />
          <PasswordInput />
          <ErrorTag />
        </Field>
        <Submit
          label="Save"
          opts={disabled: Enum.empty?(@email_changeset.changes) || !@email_changeset.valid?}
        />
      </Form>
      <h2>Update Password</h2>
      <Form
        for={@password_changeset}
        change="change_password"
        submit="submit_password"
        opts={autocomplete: "off"}
      >
        <Field name={:password}>
          <Label>New Password</Label>
          <TextInput opts={type: "password"} />
          <ErrorTag />
        </Field>
        <Field name={:password_confirmation}>
          <Label>New Password Confirmation</Label>
          <TextInput opts={type: "password"} />
          <ErrorTag />
        </Field>
        <Field name={:current_password}>
          <Label />
          <TextInput opts={type: "password"} />
          <ErrorTag />
        </Field>
        <Submit
          label="Save"
          opts={disabled: Enum.empty?(@password_changeset.changes) || !@password_changeset.valid?}
        />
      </Form>
    </Layout>
    """
  end

  @impl true
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
