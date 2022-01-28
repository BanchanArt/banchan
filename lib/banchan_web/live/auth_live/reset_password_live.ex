defmodule BanchanWeb.ResetPasswordLive do
  @moduledoc """
  Account Forgot Password?
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  alias Banchan.Accounts
  alias Banchan.Accounts.User

  alias BanchanWeb.Components.Form.TextInput
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
      <h1 class="text-2xl">Reset password</h1>
      <div class="grid grid-cols-3 gap-4">
        <Form class="col-span-1" for={@changeset} change="change" submit="submit">
          <TextInput
            name={:password}
            label="New Password"
            wrapper_class="has-icons-left"
            opts={required: true, type: :password}
          >
            <:right>
              <span class="icon is-small is-left">
                <i class="fas fa-lock" />
              </span>
            </:right>
          </TextInput>
          <TextInput
            name={:password_confirmation}
            wrapper_class="has-icons-left"
            label="Confirm New Password"
            opts={required: true, type: :password}
          >
            <:right>
              <span class="icon is-small is-left">
                <i class="fas fa-lock" />
              </span>
            </:right>
          </TextInput>
          <div class="field">
            <div class="control">
              <Submit
                class="btn text-center rounded-full py-1 px-5 btn-secondary m-1"
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
