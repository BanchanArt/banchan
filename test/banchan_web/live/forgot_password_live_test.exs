defmodule BanchanWeb.ForgotPasswordLiveTest do
  use BanchanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Banchan.AccountsFixtures
  alias Banchan.Accounts
  alias Banchan.Repo

  setup do
    %{user: user_fixture()}
  end

  test "renders the forgot password page", %{conn: conn} do
    {:ok, _view, html} = live(conn, Routes.forgot_password_path(conn, :edit))
    assert html =~ "Forgot your password?</h1>"
  end

  test "sends a new reset password token", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, Routes.forgot_password_path(conn, :edit))

    {:ok, _view, html} =
      view
      |> form("form", user: %{email: user.email})
      |> render_submit()
      |> follow_redirect(conn, Routes.home_path(conn, :index))

    assert html =~ "If your email is in our system"
    assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
  end

  test "does not send reset password token if email is invalid", %{conn: conn} do
    {:ok, view, _html} = live(conn, Routes.forgot_password_path(conn, :edit))

    {:ok, _view, html} =
      view
      |> form("form", user: %{email: "unknown@example.com"})
      |> render_submit()
      |> follow_redirect(conn, Routes.home_path(conn, :index))

    assert html =~ "If your email is in our system"
    assert Repo.all(Accounts.UserToken) == []
  end
end
