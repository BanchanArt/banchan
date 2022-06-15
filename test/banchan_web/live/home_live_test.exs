defmodule BanchanWeb.HomeLiveTest do
  @moduledoc """
  Tests for main live page
  """
  use BanchanWeb.ConnCase

  import Banchan.AccountsFixtures
  import Phoenix.LiveViewTest

  setup do
    %{user: user_fixture()}
  end

  test "render when logged out", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Log in"
    assert render(page_live) =~ "Log in"
  end

  test "render when logged in", %{conn: conn, user: user} do
    {:ok, page_live, disconnected_html} = conn |> log_in_user(user) |> live("/")
    assert disconnected_html =~ "Log out"
    assert disconnected_html =~ "Settings"
    assert render(page_live) =~ "Log out"
    assert render(page_live) =~ "Settings"
  end

  test "logs out when force logout on logged user", %{
    conn: conn
  } do
    user = user_fixture()
    conn = conn |> log_in_user(user)
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Log out"
    assert render(page_live) =~ "Log out"
    Banchan.Accounts.logout_user(user)

    # Assert our LiveView process is down
    ref = Process.monitor(page_live.pid)
    assert_receive {:DOWN, ^ref, _, _, _}
    refute Process.alive?(page_live.pid)

    # Assert our LiveView was redirected, following first to
    # /users/force_logout, then to "/", and then to "/users/log_in"

    # NB(zkat): is this really what we want? Should we just re-render in
    # this case instead? "/" isn't a login-only page.
    assert_redirect(page_live, "/force_logout")
    conn = get(conn, "/force_logout")
    assert "/" = redir_path = redirected_to(conn, 302)
    conn = get(recycle(conn), redir_path)

    assert html_response(conn, 200) =~
             "You were logged out. Please login again to continue using our application."
  end

  test "doesn't log out when force logout on another user", %{
    conn: conn
  } do
    user1 = user_fixture()
    user2 = user_fixture()
    conn = conn |> log_in_user(user2)

    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Log out"
    assert render(page_live) =~ "Log out"
    Banchan.Accounts.logout_user(user1)

    # Assert our LiveView is alive
    ref = Process.monitor(page_live.pid)
    refute_receive {:DOWN, ^ref, _, _, _}
    assert Process.alive?(page_live.pid)

    # If we are able to rerender the page it means nothing happened
    assert render(page_live) =~ "Log out"
  end
end
