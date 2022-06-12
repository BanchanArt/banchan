defmodule BanchanWeb.CommissionLive.InvoiceTest do
  @moduledoc """
  Test for the creating and managing invoices on the commissions page.
  """
  use BanchanWeb.ConnCase, async: true

  import Mox
  import Phoenix.LiveViewTest

  import Banchan.CommissionsFixtures

  alias Banchan.Notifications

  setup :verify_on_exit!

  setup do
    commission = commission_fixture()

    on_exit(fn -> Notifications.wait_for_notifications() end)

    %{
      commission: commission,
      client: commission.client,
      studio: commission.studio,
      artist: Enum.at(commission.studio.artists, 0)
    }
  end

  describe "submitting an invoice" do
    test "invoice basic", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission
    } do
      artist_conn = log_in_user(conn, artist)

      {:ok, page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      page_live
      |> form("#comment-box form", %{"event[text]": "foo", "event[amount]": "420"})
      |> render_submit()

      Notifications.wait_for_notifications()

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      refute invoice_box =~ "Payment is Requested"
      assert invoice_box =~ "Waiting for Payment"
      assert invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Pay</
      refute invoice_box =~ "modal-open"

      client_conn = log_in_user(conn, client)

      {:ok, page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "Payment is requested"
      refute invoice_box =~ "Waiting for Payment"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      assert invoice_box =~ ~r/<button[^<]+Pay</
      refute invoice_box =~ "modal-open"
    end
  end

  describe "responding to invoice" do
    test "expiring invoice", %{
      conn: conn,
      artist: artist,
      client: client,
      commission: commission
    } do
      artist_conn = log_in_user(conn, artist)

      invoice_fixture(artist, commission, %{
        "amount" => Money.new(42_000, :USD),
        "text" => "Please pay me :("
      })

      {:ok, page_live, _html} =
        live(artist_conn, Routes.commission_path(artist_conn, :show, commission.public_id))

      page_live
      |> element(".invoice-box .cancel-payment-request")
      |> render_click()

      Notifications.wait_for_notifications()

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "Payment session expired"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Pay</

      client_conn = log_in_user(conn, client)

      {:ok, page_live, _html} =
        live(client_conn, Routes.commission_path(client_conn, :show, commission.public_id))

      invoice_box =
        page_live
        |> element(".invoice-box")
        |> render()

      assert invoice_box =~ "$420.00"
      assert invoice_box =~ "Payment session expired"
      refute invoice_box =~ ~r/<button[^<]+Cancel Payment Request</
      refute invoice_box =~ ~r/<button[^<]+Pay</
    end

    test "paying an invoice" do
    end
  end

  describe "refunding an invoice" do
    test "successful refund" do
    end

    test "refunding after release" do
    end
  end

  describe "releasing an invoice" do
    test "successfully releasing invoice" do
    end
  end
end
