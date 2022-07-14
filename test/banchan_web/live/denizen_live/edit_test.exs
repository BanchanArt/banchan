defmodule BanchanWeb.DenizenLive.EditTest do
  @moduledoc """
  Tests for the user profile page.
  """
  use BanchanWeb.ConnCase

  import Banchan.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Banchan.Accounts
  alias Banchan.Notifications
  alias BanchanWeb.Router.Helpers, as: Routes

  setup do
    on_exit(fn -> Notifications.wait_for_notifications() end)
    %{user: user_fixture()}
  end

  describe "edit profile page" do
    test "redirects if logged out", %{conn: conn, user: user} do
      {:error, {:redirect, info}} = live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      assert info.to =~ Routes.login_path(conn, :new)
    end

    test "redirects if logged in as a different non-admin user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user_fixture())

      {:error, {:live_redirect, info}} =
        live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      assert info.to =~ Routes.denizen_show_path(conn, :show, user.handle)
    end

    test "preloads current profile values", %{conn: conn, user: user} do
      {:ok, user} =
        Accounts.update_user_profile(
          user,
          user,
          %{
            name: "Name",
            bio: "Bio"
          }
        )

      conn = log_in_user(conn, user)

      {:ok, page_live, disconnected_html} =
        live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      rendered_html = render(page_live)

      assert disconnected_html =~ user.handle
      assert disconnected_html =~ user.bio
      assert disconnected_html =~ user.name

      assert rendered_html =~ user.handle
      assert rendered_html =~ user.bio
      assert rendered_html =~ user.name
    end

    test "updates profile values on change, but does not change user in db", %{
      conn: conn,
      user: user
    } do
      conn = conn |> log_in_user(user)

      {:ok, page_live, _disconnected_html} =
        live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      rendered =
        page_live
        |> element(".profile-info")
        |> render_change(%{
          user: %{handle: "newhandle", bio: "new bio", name: "new name", email: "new@email"}
        })

      assert rendered =~ "newhandle"
      assert rendered =~ "new bio"
      assert rendered =~ "new name"
      refute rendered =~ "new@email"

      db_user = Accounts.get_user!(user.id)

      assert user.name == db_user.name
      assert user.bio == db_user.bio
      assert user.handle == db_user.handle
      assert user.email == db_user.email
    end

    test "validates profile values on change", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user)

      {:ok, page_live, _disconnected_html} =
        live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      rendered =
        page_live
        |> element(".profile-info")
        |> render_change(%{
          user: %{
            bio: String.duplicate("a", 500),
            name: String.duplicate("b", 50)
          }
        })

      assert rendered =~ "aaaaaaaaaaa"
      assert rendered =~ "bbbbbbbbbbb"

      assert rendered =~ "should be at most 160 character(s)"
      assert rendered =~ "should be at most 32 character(s)"
    end

    test "updates profile values on submit, updates user in db", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user)

      {:ok, page_live, _disconnected_html} =
        live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      page_live
      |> element(".profile-info")
      |> render_submit(%{
        user: %{handle: "newhandle", bio: "new bio", name: "new name", email: "new@email"}
      })

      assert_redirected(page_live, Routes.denizen_show_path(conn, :show, user.handle))

      db_user = Accounts.get_user!(user.id)

      assert db_user.name == "new name"
      assert db_user.bio == "new bio"

      # Handle and email cannot be updated through here.
      assert db_user.email == user.email
      assert db_user.handle == user.handle
    end

    test "admins can edit profiles", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user_fixture(%{roles: [:admin]}))

      {:ok, page_live, _disconnected_html} =
        live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      page_live
      |> element(".profile-info")
      |> render_submit(%{
        user: %{handle: "newhandle", bio: "new bio", name: "new name", email: "new@email"}
      })

      assert_redirected(page_live, Routes.denizen_show_path(conn, :show, user.handle))

      db_user = Accounts.get_user!(user.id)

      assert db_user.name == "new name"
      assert db_user.bio == "new bio"

      # Handle and email cannot be updated through here.
      assert db_user.email == user.email
      assert db_user.handle == user.handle
    end

    test "mods can edit profiles", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user_fixture(%{roles: [:mod]}))

      {:ok, page_live, _disconnected_html} =
        live(conn, Routes.denizen_edit_path(conn, :edit, user.handle))

      page_live
      |> element(".profile-info")
      |> render_submit(%{
        user: %{handle: "newhandle", bio: "new bio", name: "new name", email: "new@email"}
      })

      assert_redirected(page_live, Routes.denizen_show_path(conn, :show, user.handle))

      db_user = Accounts.get_user!(user.id)

      assert db_user.name == "new name"
      assert db_user.bio == "new bio"

      # Handle and email cannot be updated through here.
      assert db_user.email == user.email
      assert db_user.handle == user.handle
    end
  end
end
