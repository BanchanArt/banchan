defmodule BanchanWeb.StudioLive.Helpers do
  @moduledoc """
  Helpers for things that all the Studio-related views have in common, such as
  studio fetching, checking membership, etc.
  """
  import Phoenix.LiveView

  alias Banchan.Studios

  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  def assign_studio_defaults(%{"handle" => handle}, socket, current_member \\ true) do
    studio = Studios.get_studio_by_handle!(handle)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio(socket.assigns.current_user, studio)

    if current_member && !current_user_member? do
      socket = put_flash(socket, :error, "Access denied")
      push_redirect(socket, to: Routes.studio_shop_path(Endpoint, :show, studio.handle))
    else
      assign(socket, studio: studio, current_user_member?: current_user_member?)
    end
  end
end
