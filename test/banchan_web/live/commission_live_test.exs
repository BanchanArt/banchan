defmodule BanchanWeb.CommissionLiveTest do
  use BanchanWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Banchan.Commissions

  @create_attrs %{status: "some status", title: "some title"}
  @update_attrs %{status: "some updated status", title: "some updated title"}
  @invalid_attrs %{status: nil, title: nil}

  defp fixture(:commission) do
    {:ok, commission} = Commissions.create_commission(@create_attrs)
    commission
  end

  defp create_commission(_) do
    commission = fixture(:commission)
    %{commission: commission}
  end

  describe "Index" do
    setup [:create_commission]

    # test "lists all commissions", %{conn: conn, commission: commission} do
    #   {:ok, _index_live, html} = live(conn, Routes.commission_index_path(conn, :index))

    #   assert html =~ "Listing Commissions"
    #   assert html =~ commission.status
    # end

    # test "saves new commission", %{conn: conn} do
    #   {:ok, index_live, _html} = live(conn, Routes.commission_index_path(conn, :index))

    #   assert index_live |> element("a", "New Commission") |> render_click() =~
    #            "New Commission"

    #   assert_patch(index_live, Routes.commission_index_path(conn, :new))

    #   assert index_live
    #          |> form("#commission-form", commission: @invalid_attrs)
    #          |> render_change() =~ "can&apos;t be blank"

    #   {:ok, _, html} =
    #     index_live
    #     |> form("#commission-form", commission: @create_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, Routes.commission_index_path(conn, :index))

    #   assert html =~ "Commission created successfully"
    #   assert html =~ "some status"
    # end

    # test "updates commission in listing", %{conn: conn, commission: commission} do
    #   {:ok, index_live, _html} = live(conn, Routes.commission_index_path(conn, :index))

    #   assert index_live |> element("#commission-#{commission.id} a", "Edit") |> render_click() =~
    #            "Edit Commission"

    #   assert_patch(index_live, Routes.commission_index_path(conn, :edit, commission))

    #   assert index_live
    #          |> form("#commission-form", commission: @invalid_attrs)
    #          |> render_change() =~ "can&apos;t be blank"

    #   {:ok, _, html} =
    #     index_live
    #     |> form("#commission-form", commission: @update_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, Routes.commission_index_path(conn, :index))

    #   assert html =~ "Commission updated successfully"
    #   assert html =~ "some updated status"
    # end

    # test "deletes commission in listing", %{conn: conn, commission: commission} do
    #   {:ok, index_live, _html} = live(conn, Routes.commission_index_path(conn, :index))

    #   assert index_live |> element("#commission-#{commission.id} a", "Delete") |> render_click()
    #   refute has_element?(index_live, "#commission-#{commission.id}")
    # end
  end

  describe "Show" do
    setup [:create_commission]

    # test "displays commission", %{conn: conn, commission: commission} do
    #   {:ok, _show_live, html} = live(conn, Routes.commission_show_path(conn, :show, commission))

    #   assert html =~ "Show Commission"
    #   assert html =~ commission.status
    # end

    # test "updates commission within modal", %{conn: conn, commission: commission} do
    #   {:ok, show_live, _html} = live(conn, Routes.commission_show_path(conn, :show, commission))

    #   assert show_live |> element("a", "Edit") |> render_click() =~
    #            "Edit Commission"

    #   assert_patch(show_live, Routes.commission_show_path(conn, :edit, commission))

    #   assert show_live
    #          |> form("#commission-form", commission: @invalid_attrs)
    #          |> render_change() =~ "can&apos;t be blank"

    #   {:ok, _, html} =
    #     show_live
    #     |> form("#commission-form", commission: @update_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, Routes.commission_show_path(conn, :show, commission))

    #   assert html =~ "Commission updated successfully"
    #   assert html =~ "some updated status"
    # end
  end
end
