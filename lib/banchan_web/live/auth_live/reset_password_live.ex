defmodule BanchanWeb.ResetPasswordLive do
  @moduledoc """
  Account Forgot Password?
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Form

  alias Banchan.Accounts
  alias Banchan.Accounts.User

  alias BanchanWeb.AuthLive.Components.AuthLayout
  alias BanchanWeb.Components.Form.{Submit, TextInput}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"token" => token}, _session, socket) do
    socket =
      if user = Accounts.get_user_by_reset_password_token(token) do
        socket |> assign(user: user, token: token, changeset: Accounts.change_user_password(user))
      else
        socket
        |> put_flash(:error, "Reset password link is invalid or it has expired.")
        |> push_navigate(to: Routes.home_path(Endpoint, :index))
      end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <AuthLayout flashes={@flash}>
      <Form class="reset flex flex-col gap-4" for={@changeset} change="change" submit="submit">
        <h1 class="text-2xl">Reset Password</h1>
        <TextInput
          name={:password}
          label="New Password"
          icon="lock"
          opts={required: true, type: :password, placeholder: "your_new_secure_password"}
        />
        <TextInput
          name={:password_confirmation}
          icon="lock"
          label="Confirm New Password"
          opts={required: true, type: :password, placeholder: "your_new_secure_password"}
        />
        <Submit class="w-full" changeset={@changeset} label="Reset Password" />
      </Form>
    </AuthLayout>
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
          |> push_navigate(to: Routes.login_path(Endpoint, :new))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
