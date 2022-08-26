defmodule BanchanWeb.BetaLive.RequestsTest do
  @moduledoc """
  Test for the beta invite request management screen for admins.
  """
  use BanchanWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.InviteRequest
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
      {:error, {:redirect, info}} = live(conn, Routes.beta_requests_path(conn, :index))

      assert info.to =~ Routes.login_path(conn, :new)
    end

    test "redirects if user is not an admin or mod", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:error, {:redirect, info}} = live(conn, Routes.beta_requests_path(conn, :index))

      assert info.to =~ Routes.home_path(conn, :index)
    end

    test "renders fine if there's no requests", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      {:ok, _view, html} = live(conn, Routes.beta_requests_path(conn, :index))

      {:ok, document} = Floki.parse_document(html)

      assert [] == document |> Floki.find("table > tbody > tr")
    end

    test "renders a list of pending invite requests", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo1@example.com")
      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo2@example.com")

      {:ok, _view, html} = live(conn, Routes.beta_requests_path(conn, :index))

      {:ok, document} = Floki.parse_document(html)

      assert ["foo1@example.com", "foo2@example.com"] ==
               document
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))
    end

    test "only includes pending requests, by default", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo1@example.com")
      {:ok, %InviteRequest{} = req2} = Accounts.add_invite_request("foo2@example.com")
      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo3@example.com")

      {:ok, _request} =
        Accounts.send_invite(Accounts.system_user(), req2, &extractable_user_token/1)

      {:ok, _view, html} = live(conn, Routes.beta_requests_path(conn, :index))

      {:ok, document} = Floki.parse_document(html)

      assert ["foo1@example.com", "foo3@example.com"] ==
               document
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))
    end

    test "allows viewing all requests, even sent ones", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo1@example.com", now |> NaiveDateTime.add(-1000))

      {:ok, %InviteRequest{} = req2} =
        Accounts.add_invite_request("foo2@example.com", now |> NaiveDateTime.add(-500))

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo3@example.com", now)

      {:ok, _request} =
        Accounts.send_invite(Accounts.system_user(), req2, &extractable_user_token/1)

      {:ok, view, _html} = live(conn, Routes.beta_requests_path(conn, :index))

      html =
        view
        |> element("form.show-sent")
        |> render_change(%{"show_sent" => %{"show_sent" => "true"}})

      {:ok, document} = Floki.parse_document(html)

      assert ["foo1@example.com", "foo2@example.com", "foo3@example.com"] ==
               document
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))
    end
  end
end
