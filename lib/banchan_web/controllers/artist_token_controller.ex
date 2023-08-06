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
        |> redirect(to: ~p"/denizens/#{conn.assigns.current_user.handle}")

      {:error, :already_artist} ->
        conn
        |> put_flash(:error, "You are already an artist, so you can't use this token.")
        |> redirect(to: ~p"/denizens/#{conn.assigns.current_user.handle}")

      {:error, :invalid_token} ->
        conn
        |> put_flash(:error, "Artist invite token is invalid.")
        |> redirect(to: ~p"/denizens/#{conn.assigns.current_user.handle}")

      {:error, :token_used} ->
        conn
        |> put_flash(:error, "Artist invite token has already been used.")
        |> redirect(to: ~p"/denizens/#{conn.assigns.current_user.handle}")
    end
  end
end
