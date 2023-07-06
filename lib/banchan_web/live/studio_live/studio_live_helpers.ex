defmodule BanchanWeb.StudioLive.Helpers do
  @moduledoc """
  Helpers for things that all the Studio-related views have in common, such as
  studio fetching, checking membership, etc.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  import Ecto.Query

  alias Surface.Components.Context

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias Banchan.Studios

  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
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

    socket =
      Context.put(socket,
        studio: studio,
        current_user_member?: current_user_member?
      )

    cond do
      current_member && !current_user_member? &&
          (is_nil(socket.assigns.current_user) || !Accounts.mod?(socket.assigns.current_user)) ->
        raise Ecto.NoResultsError, queryable: from(u in User, join: s in assoc(u, :studios))

      studio.deleted_at ->
        raise Ecto.NoResultsError, queryable: from(u in User, join: s in assoc(u, :studios))

      studio.archived_at &&
          (is_nil(socket.assigns.current_user) ||
             (!current_user_member? && !Accounts.mod?(socket.assigns.current_user))) ->
        raise Ecto.NoResultsError, queryable: from(u in User, join: s in assoc(u, :studios))

      studio.disable_info &&
          (is_nil(socket.assigns.current_user) || !Accounts.mod?(socket.assigns.current_user)) ->
        socket
        |> put_flash(
          :error,
          "Studio is disabled. You can't access this page."
        )
        |> redirect(to: Routes.studio_disabled_path(Endpoint, :show, studio.handle))

      studio.mature && is_nil(socket.assigns.current_user) ->
        socket
        |> put_flash(
          :error,
          "You must be logged in to view mature studios."
        )
        |> redirect(to: Routes.discover_index_path(Endpoint, :index, "studios"))

      studio.mature && !is_nil(socket.assigns.current_user) &&
        !socket.assigns.current_user.mature_ok && !Accounts.mod?(socket.assigns.current_user) ->
        socket
        |> put_flash(
          :error,
          "This studio is marked as mature, but you have not enabled mature content, meaning it won't show up when you search for it yourself. You can enable this in your user settings."
        )
        |> redirect(to: Routes.discover_index_path(Endpoint, :index, "studios"))

      requires_stripe && !Studios.charges_enabled?(studio, false) ->
        socket
        |> put_flash(:error, "This studio is not ready to accept commissions yet.")
        |> redirect(to: Routes.studio_shop_path(Endpoint, :show, handle))

      socket.assigns.current_user && Studios.user_blocked?(studio, socket.assigns.current_user) ->
        socket
        |> put_flash(:error, "You have been blocked by studio.")
        |> redirect(to: Routes.home_path(Endpoint, :index))

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
        studio.card_img_id &&
          Routes.public_image_url(Endpoint, :image, :studio_card_img, studio.card_img_id)
    )
  end
end
