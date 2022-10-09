defmodule BanchanWeb.UserLiveAuth do
  @moduledoc """
  Handles making sure users are all authenticated within certain LiveViews
  """
  import Phoenix.LiveView
  import Phoenix.Component

  alias Banchan.Accounts
  alias Banchan.Accounts.User

  alias BanchanWeb.Router.Helpers, as: Routes

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def on_mount(auth, _params, session, socket) do
    socket =
      socket
      |> assign(page_title: "The Co-operative Commissions Platform")
      |> assign_new(:current_user, fn ->
        find_current_user(session)
      end)

    socket = Surface.Components.Context.put(socket, current_user: socket.assigns.current_user)

    cond do
      auth == :redirect_if_authed && socket.assigns.current_user ->
        {:halt,
         socket
         |> redirect(to: Routes.home_path(socket, :index))}

      socket.assigns.current_user && socket.assigns.current_user.deactivated_at &&
          auth != :deactivated ->
        {:halt,
         socket
         |> redirect(to: Routes.reactivate_path(socket, :show))}

      auth == :deactivated && socket.assigns.current_user &&
          is_nil(socket.assigns.current_user.deactivated_at) ->
        {:halt,
         socket
         |> redirect(to: Routes.home_path(socket, :index))}

      true ->
        allowed =
          case auth do
            :default ->
              true

            :open ->
              is_nil(socket.assigns.current_user) ||
                is_nil(socket.assigns.current_user.disable_info)

            :deactivated ->
              true

            :redirect_if_authed ->
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
         do: user
  end
end
