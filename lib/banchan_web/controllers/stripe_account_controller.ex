defmodule BanchanWeb.StripeAccountController do
  @moduledoc """
  Handles account-related endpoints for Stripe stuff.
  """
  use BanchanWeb, :controller

  alias Banchan.Studios

  def account_link(conn, %{"handle" => handle}) do
    studio = Studios.get_studio_by_handle!(handle)

    if conn.assigns.current_user && Studios.is_user_in_studio?(conn.assigns.current_user, studio) do
      if Studios.charges_enabled?(studio, true) do
        conn
        |> put_flash(:success, "Your account is already connected to Stripe.")
        |> redirect(to: ~p"/studios/#{studio.handle}")
      else
        url =
          Studios.get_onboarding_link!(
            studio,
            Routes.studio_shop_url(Endpoint, :show, studio.handle),
            Routes.studio_shop_url(Endpoint, :show, studio.handle)
          )

        conn
        |> redirect(external: url)
      end
    else
      conn
      |> resp(403, "Forbidden")
      |> send_resp()
    end
  end
end
