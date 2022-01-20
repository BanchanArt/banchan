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

  alias Surface.Components.Form.Input.InputContext

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
      <h1 class="text-2xl">Account Settings</h1>
      <div class="card shadow bg-neutral card-bordered text-primary-content border-2">
        <div class="card-body">
          <h2 class="text-xl card-title">Update Email</h2>
          <Form
            class="col-span-1"
            for={@email_changeset}
            change="change_email"
            submit="submit_email"
            opts={autocomplete: "off"}
          >
            <Field class="field" name={:email}>
              <Label class="label" />
              <div class="control has-icons-left">
                <InputContext :let={form: form, field: field}>
                  <EmailInput class={"input", "input-primary", "input-bordered", "input-sm", "text-base-content", "border-2", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))} />
                </InputContext>
                <span class="icon is-small is-left">
                  <i class="fas fa-envelope" />
                </span>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <Field class="field" name={:password}>
              <Label class="label" />
              <div class="control has-icons-left">
                <InputContext :let={form: form, field: field}>
                  <PasswordInput class={"input", "input-primary", "input-bordered", "input-sm", "text-base-content", "border-2", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))} />
                </InputContext>
                <span class="icon is-small is-left">
                  <i class="fas fa-lock" />
                </span>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <div class="field">
              <div class="control">
                <Submit
                  class="text-center rounded-full py-1 px-5 btn-secondary m-1"
                  label="Save"
                  opts={disabled: Enum.empty?(@email_changeset.changes) || !@email_changeset.valid?}
                />
              </div>
            </div>
          </Form>
        </div>
      </div>
      <div class="card shadow bg-neutral card-bordered text-primary-content border-2">
        <div class="card-body">
          <h2 class="text-xl card-title">Update Password</h2>
          <Form
            class="col-span-1"
            for={@password_changeset}
            change="change_password"
            submit="submit_password"
            opts={autocomplete: "off"}
          >
            <Field class="field" name={:password}>
              <Label class="label">New Password</Label>
              <div class="control has-icons-left">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={"input", "input-primary", "input-bordered", "input-sm", "text-base-content", "border-2", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                    opts={required: true, type: :password}
                  />
                </InputContext>
                <span class="icon is-small is-left">
                  <i class="fas fa-lock" />
                </span>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <Field class="field" name={:password_confirmation}>
              <Label class="label">New Password Confirmation</Label>
              <div class="control has-icons-left">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={"input", "input-primary", "input-bordered", "input-sm", "text-base-content", "border-2", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                    opts={required: true, type: :password}
                  />
                </InputContext>
                <span class="icon is-small is-left">
                  <i class="fas fa-lock" />
                </span>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <Field class="field" name={:current_confirmation}>
              <Label class="label" />
              <div class="control has-icons-left">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={"input", "input-primary", "input-bordered", "input-sm", "text-base-content", "border-2", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                    opts={required: true, type: :password}
                  />
                </InputContext>
                <span class="icon is-small is-left">
                  <i class="fas fa-lock" />
                </span>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <div class="field">
              <div class="control">
                <Submit
                  class="text-center rounded-full py-1 px-5 btn-secondary m-1"
                  label="Save"
                  opts={disabled: Enum.empty?(@password_changeset.changes) || !@password_changeset.valid?}
                />
              </div>
            </div>
          </Form>
        </div>
      </div>
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
