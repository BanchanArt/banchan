defmodule BanchanWeb.BetaLive.RequestsTest do
  @moduledoc """
  Test for the beta invite request management screen for admins.
  """
  use BanchanWeb.ConnCase, async: true
  use Bamboo.Test

  import Phoenix.LiveViewTest

  import Banchan.AccountsFixtures

  alias Banchan.Accounts
  alias Banchan.Accounts.{ArtistToken, InviteRequest}
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

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo1@example.com", now |> NaiveDateTime.add(-1000))

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo2@example.com", now)

      {:ok, _view, html} = live(conn, Routes.beta_requests_path(conn, :index))

      assert ["foo1@example.com", "foo2@example.com"] =
               html
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))
    end

    test "only includes pending requests, by default", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo1@example.com", now |> NaiveDateTime.add(-1000))

      {:ok, %InviteRequest{} = req2} =
        Accounts.add_invite_request("foo2@example.com", now |> NaiveDateTime.add(-500))

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo3@example.com", now)

      {:ok, _request} =
        Accounts.send_invite(Accounts.system_user(), req2, &extractable_user_token/1)

      {:ok, _view, html} = live(conn, Routes.beta_requests_path(conn, :index))

      assert ["foo1@example.com", "foo3@example.com"] =
               html
               |> Floki.parse_document!()
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

      {:ok, _request} = Accounts.send_invite(admin, req2, &extractable_user_token/1)

      {:ok, view, _html} = live(conn, Routes.beta_requests_path(conn, :index))

      assert ["foo1@example.com", "foo2@example.com", "foo3@example.com"] ==
               view
               |> element("form.show-sent")
               |> render_change(%{"show_sent" => %{"show_sent" => "true"}})
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))

      admin_handle = "@" <> admin.handle <> "(admin)"

      assert ["-", ^admin_handle, "-"] =
               view
               |> render()
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.generated-by")
               |> Enum.map(&Floki.text(&1))
               |> Enum.map(&Regex.replace(~r/\s*/, &1, ""))
    end

    test "shows user who used a particular invite", %{conn: conn, user: user, admin: admin} do
      conn = log_in_user(conn, admin)

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo1@example.com", now |> NaiveDateTime.add(-1000))

      {:ok, %InviteRequest{} = req2} =
        Accounts.add_invite_request("foo2@example.com", now |> NaiveDateTime.add(-500))

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo3@example.com", now)

      {:ok, _request} = Accounts.send_invite(admin, req2, &extractable_user_token/1)

      assert_delivered_email_matches(%{
        to: [{_, "foo2@example.com"}],
        text_body: text_body
      })

      %ArtistToken{token: token} = Accounts.get_artist_token(extract_user_token(text_body))

      {:ok, _token} = Accounts.apply_artist_token(user, token)

      {:ok, view, _html} = live(conn, Routes.beta_requests_path(conn, :index))

      user_handle = "@" <> user.handle

      assert ["-", ^user_handle, "-"] =
               view
               |> element("form.show-sent")
               |> render_change(%{"show_sent" => %{"show_sent" => "true"}})
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.used-by")
               |> Enum.map(&Floki.text(&1))
    end

    test "allows filtering by email", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo@example.com", now |> NaiveDateTime.add(-1000))

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("bar@example.com", now)

      {:ok, view, _html} = live(conn, Routes.beta_requests_path(conn, :index))

      assert ["bar@example.com"] =
               view
               |> element("form.email-filter")
               |> render_change(%{"filter" => "bar@"})
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))

      assert ["foo@example.com"] =
               view
               |> element("form.email-filter")
               |> render_submit(%{"filter" => "foo@"})
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))
    end

    test "allows sending an individual invite", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo1@example.com", now |> NaiveDateTime.add(-1000))

      {:ok, %InviteRequest{} = req2} =
        Accounts.add_invite_request("foo2@example.com", now |> NaiveDateTime.add(-500))

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo3@example.com", now |> NaiveDateTime.add(-200))

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo4@example.com", now)

      {:ok, _request} =
        Accounts.send_invite(Accounts.system_user(), req2, &extractable_user_token/1)

      {:ok, view, _html} = live(conn, Routes.beta_requests_path(conn, :index))

      req_path = Routes.beta_requests_path(conn, :index)

      {:error, {:live_redirect, %{to: ^req_path}}} =
        result =
        view
        |> element("table > tbody > tr:nth-child(2) > .action > button")
        |> render_click()

      {:ok, view, _html} = follow_redirect(result, conn)

      assert view
             |> render()
             |> Floki.parse_document!()
             |> Floki.find(".flash-container")
             |> Floki.text() =~ "Invite sent to foo3@example.com"

      assert ["foo1@example.com", "foo4@example.com"] =
               view
               |> render()
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))

      admin_handle = "@" <> admin.handle <> "(admin)"

      assert ["-", "@tteokbokki(system)", ^admin_handle, "-"] =
               view
               |> element("form.show-sent")
               |> render_change(%{"show_sent" => %{"show_sent" => "true"}})
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.generated-by")
               |> Enum.map(&Floki.text(&1))
               |> Enum.map(&Regex.replace(~r/\s*/, &1, ""))
    end

    test "allows sending batches of invites", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo1@example.com", now |> NaiveDateTime.add(-1000))

      {:ok, %InviteRequest{} = req2} =
        Accounts.add_invite_request("foo2@example.com", now |> NaiveDateTime.add(-500))

      {:ok, %InviteRequest{}} =
        Accounts.add_invite_request("foo3@example.com", now |> NaiveDateTime.add(-200))

      {:ok, %InviteRequest{}} = Accounts.add_invite_request("foo4@example.com", now)

      {:ok, _request} =
        Accounts.send_invite(Accounts.system_user(), req2, &extractable_user_token/1)

      {:ok, view, _html} = live(conn, Routes.beta_requests_path(conn, :index))

      req_path = Routes.beta_requests_path(conn, :index)

      {:error, {:live_redirect, %{to: ^req_path}}} =
        result =
        view
        |> element("form.send-invites")
        |> render_submit(%{"count" => "2"})

      {:ok, view, _html} = follow_redirect(result, conn)

      assert view
             |> render()
             |> Floki.parse_document!()
             |> Floki.find(".flash-container")
             |> Floki.text() =~ "Invites sent!"

      assert ["foo4@example.com"] =
               view
               |> render()
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.email")
               |> Enum.map(&Floki.text(&1))

      admin_handle = "@" <> admin.handle <> "(admin)"

      assert [^admin_handle, "@tteokbokki(system)", ^admin_handle, "-"] =
               view
               |> element("form.show-sent")
               |> render_change(%{"show_sent" => %{"show_sent" => "true"}})
               |> Floki.parse_document!()
               |> Floki.find("table > tbody > tr > td.generated-by")
               |> Enum.map(&Floki.text(&1))
               |> Enum.map(&Regex.replace(~r/\s*/, &1, ""))
    end
  end
end
