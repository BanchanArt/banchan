defmodule BespokeWeb.PageLiveTest do
  @moduledoc """
  Tests for main live page
  """
  use BespokeWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Log in"
    # assert render(page_live) =~ "Log in"
  end
end
