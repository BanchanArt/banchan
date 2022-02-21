defmodule Banchan.CommissionsTest do
  @moduledoc """
  Tests for Commissions-related functionality.
  """
  use Banchan.DataCase

  alias Banchan.Commissions

  describe "commissions" do
    alias Banchan.Commissions.Commission

    @valid_attrs %{
      status: "submitted",
      title: "some title",
      description: "Some Description",
      tos_ok: true
    }
    @update_attrs %{
      status: "accepted",
      title: "some updated title",
      description: "Some updated description",
      tos_ok: true
    }
    @invalid_attrs %{status: nil, title: nil}

    def commission_fixture(attrs \\ %{}) do
      {:ok, user} =
        Banchan.Accounts.register_admin(%{
          handle: "test-admin",
          email: "test@example.com",
          password: "foobarbazquux",
          password_confirmation: "foobarbazquux"
        })

      {:ok, studio} =
        Banchan.Studios.new_studio(
          user,
          %Banchan.Studios.Studio{artists: [user]},
          "http://localhost:4000/studios/test-studio",
          %{
            handle: "test-studio",
            name: "Test Studio",
            description: "stuff for testing"
          }
        )

      {:ok, offering} =
        Banchan.Offerings.new_offering(studio, true, %{
          type: "illustration",
          index: 0,
          name: "Illustration",
          description: "A detailed illustration with full rendering and background.",
          open: true
        })

      {:ok, commission} =
        Banchan.Commissions.create_commission(user, offering, attrs |> Enum.into(@valid_attrs))

      commission
    end

    @tag :skip
    test "list_commissions/0 returns all commissions" do
      commission = commission_fixture()
      assert Commissions.list_commissions() == [commission]
    end

    @tag :skip
    test "get_commission!/1 returns the commission with given id" do
      commission = commission_fixture()
      assert Commissions.get_commission!(commission.id) == commission
    end

    @tag :skip
    test "create_commission/1 with valid data creates a commission" do
      assert {:ok, %Commission{} = commission} = Commissions.create_commission(@valid_attrs)
      assert commission.status == :submitted
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

    @tag :skip
    test "change_commission/1 returns a commission changeset" do
      commission = commission_fixture()
      assert %Ecto.Changeset{} = Commissions.change_commission(commission)
    end
  end

  describe "commission_events" do
    alias Banchan.Commissions.Event

    import Banchan.CommissionsFixtures

    @invalid_attrs %{data: nil, type: nil}
  end
end
