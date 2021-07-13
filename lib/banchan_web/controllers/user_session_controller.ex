defmodule BanchanWeb.UserSessionController do
  use BanchanWeb, :controller

  alias Phoenix.LiveView

  alias Banchan.Accounts
  alias BanchanWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      conn
      |> put_flash(:error, "Invalid email or password")
      |> LiveView.Controller.live_render(BanchanWeb.LoginLive)
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end

  def force_logout(conn, _params) do
    conn
    |> put_flash(
      :info,
      "You were logged out. Please login again to continue using our application."
    )
    |> UserAuth.log_out_user()
  end

  def refresh_session(conn, %{"return_to" => return_to}) do
    conn
    |> put_session(return_to, Routes.settings_path(conn, :edit))
    |> UserAuth.log_in_user(conn.assigns.current_user)
  end
end
