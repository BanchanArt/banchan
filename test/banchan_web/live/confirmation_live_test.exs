defmodule BanchanWeb.ConfirmationLiveTest do
  use BanchanWeb.ConnCase

  import Phoenix.LiveViewTest
  import Banchan.AccountsFixtures
  alias Banchan.Accounts
  alias Banchan.Repo

  setup do
    %{user: user_fixture()}
  end

  test "sends a new confirmation token", %{conn: conn, user: user} do
    {:ok, view, _html} = live(conn, Routes.confirmation_path(conn, :show))

    {:ok, _view, html} =
      view
      |> form("form", user: %{email: user.email})
      |> render_submit()
      |> follow_redirect(conn, Routes.home_path(conn, :index))

    assert html =~ "If your email is in our system"
    assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
  end

  test "does not send confirmation token if User is confirmed", %{conn: conn, user: user} do
    Repo.update!(Accounts.User.confirm_changeset(user))

    {:ok, view, _html} = live(conn, Routes.confirmation_path(conn, :show))

    {:ok, _view, html} =
      view
      |> form("form", user: %{email: user.email})
      |> render_submit()
      |> follow_redirect(conn, Routes.home_path(conn, :index))

    assert html =~ "If your email is in our system"
    refute Repo.get_by(Accounts.UserToken, user_id: user.id)
  end

  test "does not send confirmation token if email is invalid", %{conn: conn} do
    {:ok, view, _html} = live(conn, Routes.confirmation_path(conn, :show))

    {:ok, _view, html} =
      view
      |> form("form", user: %{email: "unknown@example.com"})
      |> render_submit()
      |> follow_redirect(conn, Routes.home_path(conn, :index))

    assert html =~ "If your email is in our system"
    assert Repo.all(Accounts.UserToken) == []
  end
end
