defmodule BanchanWeb.StripeDashboardController do
  @moduledoc """
  Redirects studio owners to their Stripe Express Dashboard.
  """
  use BanchanWeb, :controller

  alias Banchan.Studios

  def dashboard(conn, %{"handle" => handle}) do
    studio = Studios.get_studio_by_handle!(handle)

    if conn.assigns.current_user &&
         Studios.is_user_in_studio?(conn.assigns.current_user, studio) do
      if Studios.charges_enabled?(studio, true) do
        {:ok, link} =
          Studios.express_dashboard_link(
            studio,
            Routes.studio_shop_url(Endpoint, :show, studio.handle)
          )

        conn
        |> redirect(external: link.url <> "#/account")
      else
        conn
        |> put_flash(
          :error,
          "You must onboard your studio before getting access to your Stripe Dashboard."
        )
        |> redirect(to: Routes.studio_settings_path(Endpoint, :show, studio.handle))
      end
    else
      conn
      |> resp(403, "Forbidden")
      |> send_resp()
    end
  end
end
