defmodule BanchanWeb.ResetPasswordLive do
  @moduledoc """
  Account Forgot Password?
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextInput}

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
      <h1>Reset password</h1>
      <Form for={@changeset} change="change" submit="submit">
        <Field name={:password}>
          <Label>New password</Label>
          <TextInput opts={required: true, type: :password} />
          <ErrorTag />
        </Field>
        <Field name={:password_confirmation}>
          <Label>Confirm new password</Label>
          <TextInput opts={required: true, type: :password} />
          <ErrorTag />
        </Field>
        <Submit label="Reset password" />
      </Form>
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
        socket
        |> put_flash(:info, "Password reset successfully.")
        |> push_redirect(to: Routes.login_path(Endpoint, :new))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
