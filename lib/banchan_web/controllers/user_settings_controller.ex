defmodule BanchanWeb.UserSettingsController do
  use BanchanWeb, :controller

  alias Banchan.Accounts
  alias BanchanWeb.UserAuth

  def refresh_session(conn, _params) do
    conn
    |> put_session(:user_return_to, Routes.settings_path(conn, :edit))
    |> UserAuth.log_in_user(conn.assigns.current_user)
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.settings_path(conn, :edit))
    end
  end
end
