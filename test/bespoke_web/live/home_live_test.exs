defmodule BespokeWeb.HomeLiveTest do
  @moduledoc """
  Tests for main live page
  """
  use BespokeWeb.ConnCase

  import Bespoke.AccountsFixtures
  import Phoenix.LiveViewTest

  setup do
    %{user: user_fixture()}
  end

  test "render when logged out", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Log in"
    assert disconnected_html =~ "Register"
    assert render(page_live) =~ "Log in"
    assert render(page_live) =~ "Register"
  end

  test "render when logged in", %{conn: conn, user: user} do
    {:ok, page_live, disconnected_html} = conn |> log_in_user(user) |> live("/")
    assert disconnected_html =~ "Log out"
    assert disconnected_html =~ "Settings"
    assert render(page_live) =~ "Log out"
    assert render(page_live) =~ "Settings"
  end
end
