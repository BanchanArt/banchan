defmodule BanchanWeb.StudioLive.Helpers do
  @moduledoc """
  Helpers for things that all the Studio-related views have in common, such as
  studio fetching, checking membership, etc.
  """
  import Phoenix.LiveView

  alias Banchan.Studios

  def assign_studio_defaults(%{"handle" => handle}, socket, current_member, requires_stripe) do
    studio = Studios.get_studio_by_handle!(handle)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio(socket.assigns.current_user, studio)

    if (requires_stripe && !studio.stripe_id) || (current_member && !current_user_member?) do
      throw(Ecto.NoResultsError)
    else
      assign(socket, studio: studio, current_user_member?: current_user_member?)
    end
  end
end
