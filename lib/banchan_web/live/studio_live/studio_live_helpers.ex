defmodule BanchanWeb.StudioLive.Helpers do
  @moduledoc """
  Helpers for things that all the Studio-related views have in common, such as
  studio fetching, checking membership, etc.
  """
  import Phoenix.LiveView

  alias Banchan.Studios

  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  def assign_studio_defaults(%{"handle" => handle}, socket, current_member, requires_stripe) do
    studio = Studios.get_studio_by_handle!(handle)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio?(socket.assigns.current_user, studio)

    cond do
      requires_stripe && !Studios.charges_enabled?(studio, false) ->
        socket
        |> assign(studio: studio, current_user_member?: current_user_member?)
        |> put_flash(:error, "This studio is not ready to accept commissions yet.")
        |> redirect(to: Routes.studio_shop_path(Endpoint, :show, handle))

      current_member && !current_user_member? ->
        throw(Ecto.NoResultsError)

      true ->
        socket
        |> assign(studio: studio, current_user_member?: current_user_member?)
    end
  end
end
