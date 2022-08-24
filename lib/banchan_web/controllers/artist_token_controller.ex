defmodule BanchanWeb.ArtistTokenController do
  use BanchanWeb, :controller

  alias Banchan.Accounts

  def confirm_artist(conn, %{"token" => token}) do
    case Accounts.apply_artist_token(conn.assigns.current_user, token) do
      {:ok, _} ->
        conn
        |> put_flash(
          :info,
          "Artist invite token applied successfully. You can now create studios."
        )
        |> redirect(to: Routes.studio_index_path(conn, :index))

      {:error, :already_artist} ->
        conn
        |> put_flash(:error, "You are already an artist, so you can't use this token.")
        |> redirect(to: Routes.studio_index_path(conn, :index))

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Artist invite token is invalid.")
        |> redirect(to: Routes.denizen_show_path(conn, :show, conn.assigns.current_user.handle))

      {:error, :token_used} ->
        conn
        |> put_flash(:error, "Artist invite token has already been used.")
        |> redirect(to: Routes.denizen_show_path(conn, :show, conn.assigns.current_user.handle))
    end
  end
end
