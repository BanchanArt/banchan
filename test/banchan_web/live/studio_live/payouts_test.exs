defmodule BanchanWeb.StudioLive.PayoutsTest do
  @moduledoc """
  Tests for the studio payouts management page(s).
  """
  use BanchanWeb.ConnCase, async: true

  import ExUnit.CaptureLog
  import Mox
  import Phoenix.LiveViewTest

  import Banchan.CommissionsFixtures

  alias Banchan.Commissions.LineItem
  alias Banchan.Notifications
  alias Banchan.Payments
  alias Banchan.Studios

  defp mock_balance(studio, available, pending, n \\ 1) do
    Banchan.StripeAPI.Mock
    |> expect(:retrieve_balance, n, fn opts ->
      assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

      {:ok,
       %Stripe.Balance{
         available:
           Enum.map(
             available,
             &%{
               currency: String.downcase(to_string(&1.currency)),
               amount: &1.amount
             }
           ),
         pending:
           Enum.map(
             pending,
             &%{
               currency: String.downcase(to_string(&1.currency)),
               amount: &1.amount
             }
           )
       }}
    end)
  end

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

  describe "base page behaviors" do
    test "redirects if logged out", %{conn: conn, studio: studio} do
      {:error, {:redirect, info}} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      assert info.to =~ Routes.login_path(conn, :new)
    end

    test "redirects if stripe not enabled", %{conn: conn, studio: studio, artist: artist} do
      conn = log_in_user(conn, artist)

      {:error, {:redirect, info}} =
        result = live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      assert info.to =~ Routes.studio_shop_path(conn, :show, studio.handle)

      {:ok, conn} = follow_redirect(result, conn)

      {:ok, page_live, _html} = live(conn)

      assert page_live
             |> element(".flash-container")
             |> render() =~ "This studio is not ready to accept commissions yet."
    end

    test "redirect if user is not a member", %{conn: conn, client: client, studio: studio} do
      conn = log_in_user(conn, client)

      assert {:error,
              {:redirect,
               %{flash: %{"error" => "You are not authorized to perform this action."}, to: "/"}}} ==
               live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))
    end

    test "can navigate to and from listing", %{
      conn: conn,
      artist: artist,
      studio: studio,
      commission: commission
    } do
      conn = log_in_user(conn, artist)

      Studios.update_stripe_state!(studio.stripe_id, %Stripe.Account{
        charges_enabled: true,
        details_submitted: true
      })

      net = Money.new(37_862, :USD)
      mock_balance(studio, [net], [], 3)
      process_final_payment!(commission, Money.new(69, :USD))

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, fn _ ->
        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: net.amount
             }
           ],
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)
      |> expect(:retrieve_charge, fn _ ->
        {:ok,
         %Stripe.Charge{
           balance_transaction: %Stripe.BalanceTransaction{
             status: "available"
           }
         }}
      end)
      |> expect(:create_payout, fn _, _ ->
        {:ok,
         %Stripe.Payout{
           id: stripe_payout_id,
           status: "pending",
           arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
           type: "card",
           method: "standard"
         }}
      end)

      {:ok, [payout]} = Payments.payout_studio(artist, studio)

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :show, studio.handle, payout.public_id))

      assert page_live
             |> element(".sidebar")
             # Sidebar gets hidden on mobile when there's a payout selected
             |> render() =~ "hidden md:flex"

      page_live
      |> element(".go-back")
      |> render_click()

      assert_patch(page_live, Routes.studio_payouts_path(conn, :index, studio.handle))

      refute page_live
             |> has_element?(".payout")

      refute page_live
             |> element(".sidebar")
             # Sidebar becomes main screen on mobile when there's no payout selected
             |> render() =~ "hidden md:flex"

      page_live
      |> element(".payout-row > *")
      |> render_click()

      assert_patch(
        page_live,
        Routes.studio_payouts_path(conn, :show, studio.handle, payout.public_id)
      )

      assert page_live
             |> element(".payout")
             |> render() =~ "Payout"

      assert page_live
             |> element(".sidebar")
             # Sidebar becomes main screen on mobile when there's no payout selected
             |> render() =~ "hidden md:flex"
    end
  end

  describe "listing payouts" do
  end

  describe "view stats" do
    setup %{conn: conn, studio: studio, artist: artist} do
      Studios.update_stripe_state!(studio.stripe_id, %Stripe.Account{
        charges_enabled: true,
        details_submitted: true
      })

      %{conn: log_in_user(conn, artist)}
    end

    test "Shows defaults for available balance", %{conn: conn, studio: studio} do
      mock_balance(studio, [], [])

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      assert page_live
             |> element("#available")
             |> render() =~ "No Balance Available"
    end

    test "Shows available balance", %{
      conn: conn,
      studio: studio,
      commission: commission
    } do
      mock_balance(studio, [Money.new(37_862, :USD)], [])
      process_final_payment!(commission, Money.new(69, :USD))

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      assert page_live
             |> element("#available")
             |> render() =~ "$378.62"
    end

    test "Displays multiple balance currencies reasonably", %{
      conn: conn,
      studio: studio,
      artist: artist,
      commission: comm1
    } do
      comm2 =
        commission_fixture(%{
          studio: studio,
          artist: artist,
          line_items: [
            %LineItem{
              option: nil,
              amount: Money.new(64, :JPY),
              name: "custom line item",
              description: "custom line item description"
            }
          ]
        })

      mock_balance(studio, [Money.new(42_000, :USD), Money.new(64, :JPY)], [])
      process_final_payment!(comm1)
      process_final_payment!(comm2, Money.new(0, :JPY))

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      rendered = page_live |> element("#available") |> render()

      assert rendered =~ "$378.00"
      assert rendered =~ "¥58"
    end
  end

  describe "trigger payout" do
    setup %{conn: conn, studio: studio, artist: artist} do
      Studios.update_stripe_state!(studio.stripe_id, %Stripe.Account{
        charges_enabled: true,
        details_submitted: true
      })

      %{conn: log_in_user(conn, artist)}
    end

    test "payout button disabled if no balance", %{
      conn: conn,
      artist: artist,
      studio: studio,
      commission: commission
    } do
      net = Money.new(37_862, :USD)
      mock_balance(studio, [net], [], 2)
      payment_fixture(artist, commission, Money.new(42_000, :USD), Money.new(69, :USD))

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      assert page_live
             |> element("#available button")
             |> render() =~ "disabled=\"disabled\""

      process_final_payment!(commission)

      # We don't support live-updating the page (yet?)
      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      refute page_live
             |> element("#available button")
             |> render() =~ "disabled=\"disabled\""
    end

    test "payout button triggers a payout", %{
      conn: conn,
      studio: studio,
      commission: commission
    } do
      net = Money.new(37_862, :USD)
      mock_balance(studio, [net], [], 2)
      process_final_payment!(commission, Money.new(69, :USD))

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, fn _ ->
        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: net.amount
             }
           ],
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)
      |> expect(:retrieve_charge, fn _ ->
        {:ok,
         %Stripe.Charge{
           balance_transaction: %Stripe.BalanceTransaction{
             status: "available"
           }
         }}
      end)
      |> expect(:create_payout, fn _, _ ->
        {:ok,
         %Stripe.Payout{
           id: stripe_payout_id,
           status: "pending",
           arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
           type: "card",
           method: "standard"
         }}
      end)

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      refute page_live
             |> element(".payout-rows")
             |> render() =~ "$391.24"

      assert page_live
             |> element("#available button")
             # disabled immediately
             |> render_click() =~ "disabled=\"disabled\""

      assert page_live
             |> element("#available button")
             |> render() =~ "Pay Out"

      Notifications.wait_for_notifications()

      assert page_live
             |> element(".flash-container")
             |> render() =~ "Payout sent!"

      assert page_live
             |> element(".payout-row")
             |> render() =~ "$378.62"
    end

    test "failed payouts report stripe errors", %{
      conn: conn,
      studio: studio,
      commission: commission
    } do
      net = Money.new(37_862, :USD)
      mock_balance(studio, [net], [], 2)
      process_final_payment!(commission, Money.new(69, :USD))

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, fn _ ->
        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: net.amount
             }
           ],
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)
      |> expect(:retrieve_charge, fn _ ->
        {:ok,
         %Stripe.Charge{
           balance_transaction: %Stripe.BalanceTransaction{
             status: "available"
           }
         }}
      end)
      |> expect(:create_payout, fn _, _ ->
        {:error,
         %Stripe.Error{
           message: "internal message",
           user_message: "external message",
           code: :unknown_error,
           extra: %{},
           request_id: "whatever",
           source: :stripe
         }}
      end)

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :index, studio.handle))

      refute page_live
             |> element(".payout-rows")
             |> render() =~ "$378.62"

      logged_message =
        capture_log([async: true, level: :info], fn ->
          assert page_live
                 |> element("#available button")
                 # disabled immediately
                 |> render_click() =~ "disabled=\"disabled\""

          Notifications.wait_for_notifications()

          assert page_live
                 |> element(".flash-container")
                 |> render() =~ "Payout failed: external message"
        end)

      assert logged_message =~ "Failed to create Stripe payout"
      assert logged_message =~ "whatever"

      assert page_live
             |> element(".payout-row .amount")
             |> render() =~ "$378.62"

      assert page_live
             |> element(".payout-row .badge")
             |> render() =~ "Failed"

      refute page_live
             |> element("#available button")
             |> render() =~ "disabled=\"disabled\""
    end
  end

  describe "cancel payout" do
    setup %{conn: conn, studio: studio, artist: artist} do
      Studios.update_stripe_state!(studio.stripe_id, %Stripe.Account{
        charges_enabled: true,
        details_submitted: true
      })

      %{conn: log_in_user(conn, artist)}
    end

    test "cancels payout when it's pending", %{
      conn: conn,
      artist: artist,
      studio: studio,
      commission: commission
    } do
      net = Money.new(37_862, :USD)
      mock_balance(studio, [net], [], 2)
      process_final_payment!(commission, Money.new(69, :USD))

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, fn _ ->
        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: net.amount
             }
           ],
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)
      |> expect(:retrieve_charge, fn _ ->
        {:ok,
         %Stripe.Charge{
           balance_transaction: %Stripe.BalanceTransaction{
             status: "available"
           }
         }}
      end)
      |> expect(:create_payout, fn _, _ ->
        {:ok,
         %Stripe.Payout{
           id: stripe_payout_id,
           status: "pending",
           arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
           type: "card",
           method: "standard"
         }}
      end)
      |> expect(:cancel_payout, fn payout_id, opts ->
        assert payout_id == stripe_payout_id
        assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

        {:ok, %Stripe.Payout{id: stripe_payout_id, status: "canceled"}}
      end)

      {:ok, [payout]} = Payments.payout_studio(artist, studio)

      {:ok, page_live, _html} =
        live(conn, Routes.studio_payouts_path(conn, :show, studio.handle, payout.public_id))

      page_live
      |> element(".open-modal")
      |> render_click()

      page_live
      |> element(".cancel-payout")
      |> render_click()

      assert page_live
             |> element(".payout-row .badge")
             # No change to status yet.
             |> render() =~ "Pending"

      Payments.process_payout_updated!(%Stripe.Payout{
        id: payout.stripe_payout_id,
        status: "canceled",
        arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
        type: "card",
        method: "standard",
        failure_code: nil,
        failure_message: nil
      })

      # These are run fire-and-forget, so we need to wait separately.
      Notifications.wait_for_notifications()

      assert page_live
             |> element(".payout-row .badge")
             |> render() =~ "Canceled"

      assert page_live
             |> element(".payout .badge")
             |> render() =~ "Canceled"

      # We remove the modal from the page if cancellation is disabled.
      refute page_live
             |> has_element?(".open-modal")
    end
  end
end
