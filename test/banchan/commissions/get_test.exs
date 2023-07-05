defmodule Banchan.CommissionsTest.Get do
  @moduledoc """
  Tests for functionality related to reading/fetching commission information.
  """
  use Banchan.DataCase, async: true

  import Banchan.AccountsFixtures
  import Banchan.CommissionsFixtures

  alias Banchan.Commissions
  alias Banchan.Commissions.Commission
  alias Banchan.Notifications

  describe "list_commissions/3" do
    @tag skip: "TODO"
    test "lists commissions" do
    end
  end

  describe "get_commission!/2" do
    test "artists and the client can access the commission" do
      %Commission{id: commission_id} = commission = commission_fixture()

      assert %Commission{id: ^commission_id} =
               Commissions.get_commission!(commission.public_id, commission.client)

      assert %Commission{id: ^commission_id} =
               Commissions.get_commission!(
                 commission.public_id,
                 commission.studio.artists |> Enum.at(0)
               )
    end

    test "non-participants can't access the commission" do
      commission = commission_fixture()
      rando = user_fixture()

      catch_error(Commissions.get_commission!(commission.public_id, rando))
    end

    test "errors if the commission does not exist" do
      user = user_fixture()

      catch_error(Commissions.get_commission!("NotAnID", user))
    end
  end

  describe "get_public_id!/1" do
    test "returns the public ID of a commission, given its id" do
      commission = commission_fixture()

      assert commission.public_id == Commissions.get_public_id!(commission.id)
    end

    test "fails if the commission does not exist" do
      catch_error(Commissions.get_public_id!("NotAnID"))
    end
  end

  describe "archived?/2" do
    test "returns true if the user has archived the commission" do
      commission = commission_fixture()

      refute Commissions.archived?(commission.client, commission)

      {:ok, _} = Commissions.update_archived(commission.client, commission, true)

      assert Commissions.archived?(commission.client, commission)
    end
  end

  describe "commission_open?/1" do
    test "returns true if the commission is an open state, false otherwise" do
      # Open Statuses
      commission = commission_fixture()
      artist = commission.studio.artists |> Enum.at(0)

      assert Commissions.commission_open?(commission)

      {:ok, commission} = Commissions.update_status(artist, commission, :accepted)
      assert Commissions.commission_open?(commission)

      {:ok, commission} = Commissions.update_status(artist, commission, :paused)
      assert Commissions.commission_open?(commission)

      {:ok, commission} = Commissions.update_status(artist, commission, :in_progress)
      assert Commissions.commission_open?(commission)

      {:ok, commission} = Commissions.update_status(artist, commission, :waiting)
      assert Commissions.commission_open?(commission)

      # Closed statuses
      process_final_payment!(commission)
      refute Commissions.commission_open?(commission |> Repo.reload!())

      commission = commission_fixture()
      client = commission.client

      {:ok, commission} = Commissions.update_status(client, commission, :withdrawn)
      refute Commissions.commission_open?(commission)

      commission = commission_fixture()
      artist = commission.studio.artists |> Enum.at(0)

      {:ok, commission} = Commissions.update_status(artist, commission, :rejected)
      refute Commissions.commission_open?(commission)

      Notifications.wait_for_notifications()
    end
  end

  describe "get_attachment_if_allowed!/3" do
    @tag skip: "TODO - skipping upload-related tests for now"
    test "gets an EventAttachment if the user has access to it" do
    end
  end

  describe "deposited_amount/3" do
    @tag skip: "TODO - this one's a pain"
    test "returns the deposited amount of a commission" do
    end
  end

  describe "tipped_amount/3" do
    @tag skip: "TODO - this one's a pain"
    test "returns the tipped amount of a commission" do
    end
  end

  describe "line_item_estimate/1" do
    @tag skip: "TODO - this one's a pain"
    test "returns an estimate based on the given line items" do
    end
  end

  describe "list_attachments/1" do
    @tag skip: "TODO - skipping upload-related ones for now."
    test "returns all attachments associated with a commission" do
    end
  end
end
