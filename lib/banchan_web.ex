defmodule BanchanWeb do
  @moduledoc """
  The entry point for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use BanchanWeb, :controller
      use BanchanWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(
    assets fonts images js robots.txt android-chrome-96x96.png
    apple-touch-icon.png browserconfig.xml favicon-16x16.png
    favicon-32x32.png mstile-150x150.png site.webmanifest .well-known
  )

  def controller do
    quote do
      use Phoenix.Controller, namespace: BanchanWeb

      import Plug.Conn
      import BanchanWeb.Gettext

      unquote(verified_routes())

      alias BanchanWeb.Endpoint
      alias BanchanWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/banchan_web/templates",
        namespace: BanchanWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def surface_view do
    quote do
      use Surface.LiveView

      unquote(view_helpers())

      alias Banchan.Accounts.User

      def handle_info({:_internal_patch_to, url, opts}, socket) do
        {:noreply, push_patch(socket, [{:to, url} | opts])}
      end

      def handle_info(%{event: "new_notification", payload: notification}, socket) do
        # credo:disable-for-next-line Credo.Check.Design.AliasUsage
        BanchanWeb.Components.Notifications.new_notification("notifications", notification)
        {:noreply, socket}
      end

      def handle_info(%{event: "notification_read", payload: notification_ref}, socket) do
        # credo:disable-for-next-line Credo.Check.Design.AliasUsage
        BanchanWeb.Components.Notifications.notification_read("notifications", notification_ref)
        {:noreply, socket}
      end

      def handle_info(%{event: "all_notifications_read"}, socket) do
        # credo:disable-for-next-line Credo.Check.Design.AliasUsage
        BanchanWeb.Components.Notifications.all_notifications_read("notifications")
        {:noreply, socket}
      end

      # credo:disable-for-next-line Credo.Check.Design.AliasUsage
      def handle_info(%{event: "logout_user", payload: %{user: %User{id: id}}}, socket) do
        case socket.assigns.current_user do
          %User{id: ^id} ->
            {:noreply,
             socket
             |> redirect(to: Routes.user_session_path(socket, :force_logout))}

          _ ->
            {:noreply, socket}
        end
      end
    end
  end

  def component(args \\ []) do
    quote do
      use Surface.Component, unquote(args)

      unquote(view_helpers())
    end
  end

  def live_component(args \\ []) do
    quote do
      use Surface.LiveComponent, unquote(args)

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import BanchanWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import BanchanWeb.ErrorHelpers
      import BanchanWeb.Gettext

      alias BanchanWeb.Endpoint
      alias BanchanWeb.Router.Helpers, as: Routes

      import Surface

      unquote(verified_routes())

      defp internal_patch_to(url, opts) do
        send(self(), {:_internal_patch_to, url, opts})
      end
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: BanchanWeb.Endpoint,
        router: BanchanWeb.Router,
        statics: BanchanWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmacro __using__(which) when is_list(which) do
    apply(__MODULE__, Keyword.get(which, :type), [which])
  end
end
