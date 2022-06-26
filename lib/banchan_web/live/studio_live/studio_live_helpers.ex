defmodule BanchanWeb.StudioLive.Helpers do
  @moduledoc """
  Helpers for things that all the Studio-related views have in common, such as
  studio fetching, checking membership, etc.
  """
  import Phoenix.LiveView

  import Ecto.Query

  alias Banchan.Accounts.User
  alias Banchan.Studios

  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  def assign_studio_defaults(%{"handle" => handle}, socket, current_member, requires_stripe) do
    studio = Studios.get_studio_by_handle!(handle)

    current_user_member? =
      socket.assigns.current_user &&
        Studios.is_user_in_studio?(socket.assigns.current_user, studio)

    socket =
      socket
      |> assign_card_props(studio)
      |> assign(studio: studio)
      |> assign(current_user_member?: current_user_member?)
      |> assign(followers: Studios.Notifications.follower_count(studio))

    Studios.Notifications.subscribe_to_follower_count(studio)

    cond do
      current_member && !current_user_member? ->
        raise Ecto.NoResultsError, queryable: from(u in User, join: s in assoc(u, :studios))

      requires_stripe && !Studios.charges_enabled?(studio, false) ->
        socket
        |> put_flash(:error, "This studio is not ready to accept commissions yet.")
        |> redirect(to: Routes.studio_shop_path(Endpoint, :show, handle))

      true ->
        socket
    end
  end

  def assign_card_props(socket, studio) do
    socket
    |> assign(page_title: studio.name)
    |> assign(
      page_description: studio.about && HtmlSanitizeEx.strip_tags(Earmark.as_html!(studio.about))
    )
    |> assign(
      page_image:
        (studio.card_img_id || studio.header_img_id) &&
          Routes.public_image_url(Endpoint, :image, studio.card_img_id || studio.header_img_id)
    )
  end
end
