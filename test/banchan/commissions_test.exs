defmodule Banchan.CommissionsTest do
  use Banchan.DataCase

  alias Banchan.Commissions

  describe "commissions" do
    alias Banchan.Commissions.Commission

    @valid_attrs %{status: "pending", title: "some title"}
    @update_attrs %{status: "accepted", title: "some updated title"}
    @invalid_attrs %{status: nil, title: nil}

    def commission_fixture(attrs \\ %{}) do
      {:ok, user} =
        Banchan.Accounts.register_admin(%{
          handle: "zkat",
          email: "kat@dwg.dev",
          password: "foobarbazquux",
          password_confirmation: "foobarbazquux"
        })

      {:ok, studio} =
        Banchan.Studios.new_studio(%Banchan.Studios.Studio{artists: [user]}, %{
          handle: "kitteh-studio",
          name: "Kitteh Studio",
          description: "Kitteh-related stuff"
        })

      {:ok, offering} =
        Banchan.Studios.new_offering(studio, %{
          type: "illustration",
          index: 0,
          name: "Illustration",
          description: "A detailed illustration with full rendering and background.",
          open: true
        })

      {:ok, commission} =
        Banchan.Commissions.create_commission(offering, attrs |> Enum.into(@valid_attrs))

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

    @tag :skip
    test "create_commission/1 with valid data creates a commission" do
      assert {:ok, %Commission{} = commission} = Commissions.create_commission(@valid_attrs)
      assert commission.status == :pending
      assert commission.title == "some title"
    end

    @tag :skip
    test "create_commission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Commissions.create_commission(@invalid_attrs)
    end

    @tag :skip
    test "update_commission/2 with valid data updates the commission" do
      commission = commission_fixture()

      assert {:ok, %Commission{} = commission} =
               Commissions.update_commission(commission, @update_attrs)

      assert commission.status == :accepted
      assert commission.title == "some updated title"
    end

    @tag :skip
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

    @tag :skip
    test "change_commission/1 returns a commission changeset" do
      commission = commission_fixture()
      assert %Ecto.Changeset{} = Commissions.change_commission(commission)
    end
  end
end
