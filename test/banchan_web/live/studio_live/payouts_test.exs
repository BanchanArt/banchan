defmodule BanchanWeb.StudioLive.PayoutsTest do
  @moduledoc """
  Tests for the studio payouts management page(s).
  """
  use BanchanWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  import Banchan.CommissionsFixtures

  describe "listing payouts" do
    setup do
      commission = commission_fixture()

      %{
        commission: commission,
        client: commission.client,
        studio: commission.studio,
        artist: Enum.at(commission.studio.artists, 0)
      }
    end

    test "redirects if logged out", %{conn: conn, studio: studio} do
      {:error, {:redirect, info}} =
        live(conn, Routes.studio_payouts_path(conn, :show, studio.handle))

      assert info.to =~ Routes.login_path(conn, :new)
    end

    test "404 if user is not a member", %{conn: conn, client: client, studio: studio} do
      conn = log_in_user(conn, client)

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, Routes.studio_payouts_path(conn, :show, studio.handle))
      end
    end
  end

  describe "view stats" do
  end

  describe "trigger payout" do
  end
end
