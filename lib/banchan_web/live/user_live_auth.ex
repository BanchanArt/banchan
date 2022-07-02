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
      socket
      |> assign(page_title: "Art Goes Here")
      |> assign_new(:current_user, fn ->
        find_current_user(session)
      end)

    allowed =
      case auth do
        :default ->
          true

        :users_only ->
          !is_nil(socket.assigns.current_user)

        :admins_only ->
          !is_nil(socket.assigns.current_user) && :admin in socket.assigns.current_user.roles

        :artists_only ->
          !is_nil(socket.assigns.current_user) &&
            (:artist in socket.assigns.current_user.roles ||
               :admin in socket.assigns.current_user.roles)
      end

    if allowed do
      # This is important so clients get booted when they log out elsewhere.
      Accounts.subscribe_to_auth_events()

      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "You do not have access to this page.")
       |> redirect(to: Routes.user_session_path(socket, :create))}
    end
  end

  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user
  end
end
