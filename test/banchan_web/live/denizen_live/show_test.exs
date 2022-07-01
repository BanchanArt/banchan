defmodule BanchanWeb.DenizenLive.ShowTest do
  @moduledoc """
  Tests for the user profile page.
  """
  use BanchanWeb.ConnCase

  import Banchan.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Banchan.Notifications

  alias BanchanWeb.Router.Helpers, as: Routes

  setup do
    on_exit(fn -> Notifications.wait_for_notifications() end)
    %{user: user_fixture()}
  end

  describe "view profile page" do
    test "displays user data", %{conn: conn, user: user} do
      {:ok, user} =
        Banchan.Accounts.update_user_profile(
          user,
          %{bio: "This is my bio", name: "New User"},
          nil,
          nil
        )

      conn = Plug.Conn.assign(conn, :user, user)

      {:ok, page_live, disconnected_html} =
        live(conn, Routes.denizen_show_path(conn, :show, user.handle))

      rendered_html = render(page_live)

      assert disconnected_html =~ user.handle
      assert rendered_html =~ user.handle
      assert disconnected_html =~ user.bio
      assert rendered_html =~ user.bio
      assert disconnected_html =~ user.name
      assert rendered_html =~ user.name
    end
  end
end
