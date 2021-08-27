defmodule BanchanWeb.ResetPasswordLive do
  @moduledoc """
  Account Forgot Password?
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"token" => token}, session, socket) do
    socket = assign_defaults(session, socket, false)

    socket =
      if user = Accounts.get_user_by_reset_password_token(token) do
        socket |> assign(user: user, token: token, changeset: Accounts.change_user_password(user))
      else
        socket
        |> put_flash(:error, "Reset password link is invalid or it has expired.")
        |> push_redirect(to: Routes.home_path(Endpoint, :index))
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="title">Reset password</h1>
      <div class="columns">
        <Form class="column is-one-third" for={@changeset} change="change" submit="submit">
          <Field class="field" name={:password}>
            <Label class="label">New Password</Label>
            <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
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
            <Label class="label">Confirm New Password</Label>
            <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
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
                class="button is-link"
                label="Reset password"
                opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
              />
            </div>
          </div>
        </Form>
      </div>
    </Layout>
    """
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      %User{}
      |> User.password_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        socket =
          socket
          |> put_flash(:info, "Password reset successfully.")
          |> push_redirect(to: Routes.login_path(Endpoint, :new))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
