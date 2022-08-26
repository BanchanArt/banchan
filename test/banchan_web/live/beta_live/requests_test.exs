defmodule BanchanWeb.BetaLive.RequestsTest do
  @moduledoc """
  Test for the beta invite request management screen for admins.
  """
  use BanchanWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  import Banchan.AccountsFixtures

  alias Banchan.Notifications

  setup do
    on_exit(fn -> Notifications.wait_for_notifications() end)

    %{
      user: user_fixture(),
      admin: user_fixture(%{roles: [:admin]}),
      mod: user_fixture(%{roles: [:mod]})
    }
  end

  describe "invite request management page" do
    test "redirects if logged out", %{conn: conn} do
      {:error, {:redirect, info}} =
        live(conn, Routes.beta_requests_path(conn, :index))

      assert info.to =~ Routes.login_path(conn, :new)
    end

    test "redirects if user is not an admin or mod", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:error, {:redirect, info}} =
        live(conn, Routes.beta_requests_path(conn, :index))

      assert info.to =~ Routes.home_path(conn, :index)
    end
  end
end
