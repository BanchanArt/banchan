defmodule BanchanWeb.UserLiveAuth do
  @moduledoc """
  Handles making sure users are all authenticated within certain LiveViews
  """
  import Phoenix.LiveView

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias BanchanWeb.Router.Helpers, as: Routes

  def on_mount(auth, _params, session, socket) do
    socket =
      assign_new(socket, :current_user, fn ->
        find_current_user(session)
      end)

    if auth == :users_only || (auth == :admins_only && is_nil(socket.assigns.current_user)) do
      {:halt,
       socket
       |> put_flash(:error, "You must log in to access this page.")
       |> redirect(to: Routes.user_session_path(socket, :create))}
    else
      # This is important so clients get booted when they log out elsewhere.
      Accounts.subscribe_to_auth_events()

      {:cont, socket}
    end
  end

  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
  end
end
