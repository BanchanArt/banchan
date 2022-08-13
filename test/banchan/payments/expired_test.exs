defmodule Banchan.PaymentsTest.Expired do
  @moduledoc """
  Tests for the handling of expired invoices.
  """
  use Banchan.DataCase, async: true

  import Mox

  import Banchan.CommissionsFixtures

  alias Banchan.Notifications
  alias Banchan.Payments
  alias Banchan.Payments.Invoice

  setup :verify_on_exit!

  setup do
    commission = commission_fixture()

    on_exit(fn -> Notifications.wait_for_notifications() end)

    %{
      commission: commission,
      client: commission.client,
      studio: commission.studio,
      artist: Enum.at(commission.studio.artists, 0),
      amount: Money.new(42_000, :USD),
      tip: Money.new(6900, :USD)
    }
  end

  describe "purge_expired_invoice/1" do
    test "ignores invoices that aren't either :succeeded or :released", %{
      artist: artist,
      commission: commission,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} =
        invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :)"
        })

      assert {:ok, %Invoice{id: ^invoice_id}} = Payments.purge_expired_invoice(invoice)
      invoice = Repo.reload(invoice)
      assert %Invoice{status: :pending} = invoice

      session = checkout_session_fixture(invoice, tip)
      assert {:ok, %Invoice{id: ^invoice_id}} = Payments.purge_expired_invoice(invoice)
      invoice = Repo.reload(invoice)
      assert %Invoice{status: :submitted} = invoice

      expire_mock_payment(session)
      assert {:ok, %Invoice{id: ^invoice_id}} = Payments.purge_expired_invoice(invoice)
      invoice = Repo.reload(invoice)
      assert %Invoice{status: :expired} = invoice
    end

    test "initiates refunds for :succeeded invoices", %{
      artist: artist,
      commission: commission,
      amount: amount,
      tip: tip
    } do
      %Invoice{id: invoice_id} = invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "Please pay me :x"
        })

      invoice
      |> checkout_session_fixture(tip)
      |> succeed_mock_payment!()

      mock_refund_stripe_calls(invoice)

      assert {:ok, %Invoice{id: ^invoice_id, status: :refunded}} =
               Payments.purge_expired_invoice(invoice)

      assert %Invoice{status: :refunded} = Repo.reload(invoice)
    end

    @tag skip: "TODO"
    test "ignores :released invoices that have already been included in a payout" do
    end

    @tag skip: "TODO"
    test "Initiates a single-invoice payout for non-paid-out, expired :released invoices" do
    end
  end
end
