defmodule BespokeWeb.PageLiveTest do
  @moduledoc """
  Tests for main live page
  """
  use BespokeWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "no current_user"
    assert render(page_live) =~ "no current_user"
  end
end
