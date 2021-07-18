defmodule Banchan.CommissionsTest do
  use Banchan.DataCase

  alias Banchan.Commissions

  describe "commissions" do
    alias Banchan.Commissions.Commission

    @valid_attrs %{status: "some status", title: "some title"}
    @update_attrs %{status: "some updated status", title: "some updated title"}
    @invalid_attrs %{status: nil, title: nil}

    def commission_fixture(attrs \\ %{}) do
      {:ok, commission} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Commissions.create_commission()

      commission
    end

    test "list_commissions/0 returns all commissions" do
      commission = commission_fixture()
      assert Commissions.list_commissions() == [commission]
    end

    test "get_commission!/1 returns the commission with given id" do
      commission = commission_fixture()
      assert Commissions.get_commission!(commission.id) == commission
    end

    test "create_commission/1 with valid data creates a commission" do
      assert {:ok, %Commission{} = commission} = Commissions.create_commission(@valid_attrs)
      assert commission.status == "some status"
      assert commission.title == "some title"
    end

    test "create_commission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Commissions.create_commission(@invalid_attrs)
    end

    test "update_commission/2 with valid data updates the commission" do
      commission = commission_fixture()

      assert {:ok, %Commission{} = commission} =
               Commissions.update_commission(commission, @update_attrs)

      assert commission.status == "some updated status"
      assert commission.title == "some updated title"
    end

    test "update_commission/2 with invalid data returns error changeset" do
      commission = commission_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Commissions.update_commission(commission, @invalid_attrs)

      assert commission == Commissions.get_commission!(commission.id)
    end

    test "delete_commission/1 deletes the commission" do
      commission = commission_fixture()
      assert {:ok, %Commission{}} = Commissions.delete_commission(commission)
      assert_raise Ecto.NoResultsError, fn -> Commissions.get_commission!(commission.id) end
    end

    test "change_commission/1 returns a commission changeset" do
      commission = commission_fixture()
      assert %Ecto.Changeset{} = Commissions.change_commission(commission)
    end
  end
end
