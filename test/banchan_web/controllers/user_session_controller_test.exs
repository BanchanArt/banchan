defmodule BanchanWeb.UserSessionControllerTest do
  use BanchanWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  import Banchan.AccountsFixtures

  setup do
    mfa_attrs = %{totp_secret: NimbleTOTP.secret(), totp_activated: true}
    %{user: user_fixture(), user_mfa: user_fixture(mfa_attrs)}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.login_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Log in</h1>"
      assert response =~ "Log in"
      assert response =~ "Register"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(Routes.login_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in using their email", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.email,
            "password" => valid_user_password(),
            "mfa_token" => nil
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.handle
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "logs the user in using their handle", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.handle,
            "password" => valid_user_password(),
            "mfa_token" => nil
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.handle
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "logs the user in with MFA", %{conn: conn, user_mfa: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.email,
            "password" => valid_user_password(),
            "mfa_token" => NimbleTOTP.verification_code(user.totp_secret)
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.handle
      assert response =~ "Settings"
      assert response =~ "Log out"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true",
            "mfa_token" => nil
          }
        })

      assert conn.resp_cookies["_banchan_web_user_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "logs the user in with return to", %{conn: conn, user: user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.email,
            "password" => valid_user_password(),
            "mfa_token" => nil
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.email,
            "password" => "invalid_password",
            "mfa_token" => nil
          }
        })

      response = html_response(conn, 302)
      assert response =~ "redirected"

      {"location", loc} = Enum.find(conn.resp_headers, fn {k, _} -> k == "location" end)
      {:ok, _, html} = live(conn, loc)
      assert html =~ "Log in</h1>"
      assert html =~ "Invalid email/handle, password, or MFA token"
    end

    test "emits error message with valid credentials no MFA", %{conn: conn, user_mfa: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.email,
            "password" => valid_user_password(),
            "mfa_token" => nil
          }
        })

      response = html_response(conn, 302)
      assert response =~ "redirected"

      {"location", loc} = Enum.find(conn.resp_headers, fn {k, _} -> k == "location" end)
      {:ok, _, html} = live(conn, loc)
      assert html =~ "Log in</h1>"
      assert html =~ "Invalid email/handle, password, or MFA token"
    end

    test "emits error message with valid credentials wrong MFA", %{conn: conn, user_mfa: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "identifier" => user.email,
            "password" => valid_user_password(),
            "mfa_token" => "000"
          }
        })

      response = html_response(conn, 302)
      assert response =~ "redirected"

      {"location", loc} = Enum.find(conn.resp_headers, fn {k, _} -> k == "location" end)
      {:ok, _, html} = live(conn, loc)
      assert html =~ "Log in</h1>"
      assert html =~ "Invalid email/handle, password, or MFA token"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
