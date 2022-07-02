defmodule BanchanWeb.UserLiveAuth do
  @moduledoc """
  Handles making sure users are all authenticated within certain LiveViews
  """
  import Phoenix.LiveView

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Repo

  alias BanchanWeb.Router.Helpers, as: Routes

  def on_mount(auth, _params, session, socket) do
    socket =
      socket
      |> assign(page_title: "Art Goes Here")
      |> assign_new(:current_user, fn ->
        find_current_user(session)
      end)

    if auth == :redirect_if_authed && socket.assigns.current_user do
      {:halt,
       socket
       |> redirect(to: Routes.home_path(socket, :index))}
    else
      allowed =
        case auth do
          :default ->
            true

          :open ->
            true

          :users_only ->
            !is_nil(socket.assigns.current_user) &&
              is_nil(socket.assigns.current_user.disable_info)

          :admins_only ->
            !is_nil(socket.assigns.current_user) &&
              is_nil(socket.assigns.current_user.disable_info) &&
              :admin in socket.assigns.current_user.roles

          :mods_only ->
            !is_nil(
              socket.assigns.current_user &&
                is_nil(socket.assigns.current_user.disable_info) &&
                (:mod in socket.assigns.current_user.roles ||
                   :admin in socket.assigns.current_user.roles)
            )

          :artists_only ->
            !is_nil(socket.assigns.current_user) &&
              is_nil(socket.assigns.current_user.disable_info) &&
              (:artist in socket.assigns.current_user.roles ||
                 :mod in socket.assigns.current_user.roles ||
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
  end

  defp find_current_user(session) do
    with user_token when not is_nil(user_token) <- session["user_token"],
         %User{} = user <- Accounts.get_user_by_session_token(user_token),
         do: user |> Repo.preload(:disable_info)
  end
end
