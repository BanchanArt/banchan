defmodule BanchanWeb.LiveHelpers do
  @moduledoc false

  import Phoenix.LiveView

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias BanchanWeb.Router.Helpers, as: Routes
  alias BanchanWeb.UserAuth

  def assign_defaults(session, socket, auth \\ true) do
    # This is important so clients get booted when they log out elsewhere.
    BanchanWeb.Endpoint.subscribe(UserAuth.pubsub_topic())

    socket =
      assign_new(socket, :current_user, fn ->
        find_current_user(session)
      end)

    if auth && (is_nil(socket.assigns.current_user) || session.mfa_required) do
      socket
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: Routes.user_session_path(socket, :create))
    else
      socket
    end
  end

  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
  end
end
