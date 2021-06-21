defmodule BespokeWeb.LiveHelpers do
  @moduledoc false

  import Phoenix.LiveView
  alias Bespoke.Accounts
  alias Bespoke.Accounts.User
  alias BespokeWeb.UserAuth
  # alias BespokeWeb.Router.Helpers, as: Routes

  def assign_defaults(session, socket) do
    # This is important so clients get booted when they log out elsewhere.
    BespokeWeb.Endpoint.subscribe(UserAuth.pubsub_topic())
    assign_new(socket, :current_user, fn ->
      find_current_user(session)
    end)

    # Use the following if you want to force redirect / for logged out folks
    # case socket.assigns.current_user do
    #   %User{} ->
    #     socket

    #   _other ->
    #     socket
    #     |> put_flash(:error, "You must log in to access this page.")
    #     |> redirect(to: Routes.user_session_path(socket, :new))
    # end
  end

  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
  end

end
