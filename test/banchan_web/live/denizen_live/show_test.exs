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
          user,
          %{bio: "This is my bio", name: "New User"}
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

    test "displays follow button for other logged in users only", %{conn: conn, user: user} do
      stranger_conn = log_in_user(conn, user_fixture())
      self_conn = log_in_user(conn, user)

      {:ok, _, html} = live(conn, Routes.denizen_show_path(conn, :show, user.handle))
      refute html =~ ~r/>\s+Follow\s+</

      {:ok, _, html} = live(stranger_conn, Routes.denizen_show_path(conn, :show, user.handle))
      assert html =~ ~r/>\s+Follow\s+</

      {:ok, _, html} = live(self_conn, Routes.denizen_show_path(conn, :show, user.handle))
      refute html =~ ~r/>\s+Follow\s+</
    end

    test "displays edit profile button for self, admins, and mods only", %{conn: conn, user: user} do
      stranger_conn = log_in_user(conn, user_fixture())
      admin_conn = log_in_user(conn, user_fixture(%{roles: [:admin]}))
      mod_conn = log_in_user(conn, user_fixture(%{roles: [:mod]}))
      self_conn = log_in_user(conn, user)

      {:ok, _, html} = live(conn, Routes.denizen_show_path(conn, :show, user.handle))
      refute html =~ "Edit Profile"

      {:ok, _, html} = live(stranger_conn, Routes.denizen_show_path(conn, :show, user.handle))
      refute html =~ "Edit Profile"

      {:ok, _, html} = live(self_conn, Routes.denizen_show_path(conn, :show, user.handle))
      assert html =~ "Edit Profile"

      {:ok, _, html} = live(mod_conn, Routes.denizen_show_path(conn, :show, user.handle))
      assert html =~ "Edit Profile"

      {:ok, _, html} = live(admin_conn, Routes.denizen_show_path(conn, :show, user.handle))
      assert html =~ "Edit Profile"
    end

    test "displays moderation button for admins and mods only", %{conn: conn, user: user} do
      stranger_conn = log_in_user(conn, user_fixture())
      admin_conn = log_in_user(conn, user_fixture(%{roles: [:admin]}))
      mod_conn = log_in_user(conn, user_fixture(%{roles: [:mod]}))
      self_conn = log_in_user(conn, user)

      {:ok, _, html} = live(conn, Routes.denizen_show_path(conn, :show, user.handle))
      refute html =~ "Moderation"

      {:ok, _, html} = live(stranger_conn, Routes.denizen_show_path(conn, :show, user.handle))
      refute html =~ "Moderation"

      {:ok, _, html} = live(self_conn, Routes.denizen_show_path(conn, :show, user.handle))
      refute html =~ "Moderation"

      {:ok, _, html} = live(mod_conn, Routes.denizen_show_path(conn, :show, user.handle))
      assert html =~ "Moderation"

      {:ok, _, html} = live(admin_conn, Routes.denizen_show_path(conn, :show, user.handle))
      assert html =~ "Moderation"
    end
  end
end
