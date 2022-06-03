defmodule Banchan.StudiosTest do
  @moduledoc """
  Tests for Studios-related functionality.
  """
  use Banchan.DataCase, async: true

  import Mox

  import ExUnit.CaptureLog

  import Banchan.AccountsFixtures
  import Banchan.CommissionsFixtures
  import Banchan.StudiosFixtures

  alias Banchan.Commissions
  alias Banchan.Commissions.Invoice
  alias Banchan.Notifications
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Studios.{Payout, Studio}

  setup :verify_on_exit!

  describe "validation" do
    test "cannot use an existing handle" do
      user = user_fixture()
      existing_studio = studio_fixture([user])

      changeset =
        Studio.profile_changeset(
          %Studio{},
          %{name: "valid name", handle: existing_studio.handle}
        )

      refute changeset.valid?
    end

    test "cannot use an existing user handle" do
      user = user_fixture()

      changeset =
        Studio.profile_changeset(
          %Studio{},
          %{name: "valid name", handle: user.handle}
        )

      refute changeset.valid?
    end
  end

  describe "creation" do
    test "create and enable a studio" do
      user = user_fixture()
      stripe_id = unique_stripe_id()
      studio_handle = unique_studio_handle()
      studio_name = unique_studio_name()
      studio_url = "http://localhost:4000/studios/#{studio_handle}"

      Banchan.StripeAPI.Mock
      |> expect(:create_account, fn attrs ->
        assert "express" == attrs.type
        assert %{payouts: %{schedule: %{interval: "manual"}}} == attrs.settings
        assert studio_url == attrs.business_profile.url
        {:ok, %Stripe.Account{id: stripe_id}}
      end)

      {:ok, studio} =
        Banchan.Studios.new_studio(
          %Studio{artists: [user]},
          studio_url,
          %{
            name: studio_name,
            handle: studio_handle
          }
        )

      assert studio.stripe_id == stripe_id
      assert studio.handle == studio_handle
      assert studio.name == studio_name

      Repo.transaction(fn ->
        subscribers =
          studio
          |> Notifications.studio_subscribers()
          |> Enum.map(& &1.id)

        assert subscribers == [user.id]
      end)
    end
  end

  describe "updating" do
    test "update studio profile" do
      user = user_fixture()
      studio = studio_fixture([user])

      attrs = %{
        name: "new name",
        handle: "new-handle",
        description: "new description",
        summary: "new summary",
        default_terms: "new terms",
        default_template: "new template"
      }

      {:error, :unauthorized} =
        Studios.update_studio_profile(
          studio,
          false,
          attrs
        )

      from_db = Repo.get!(Studio, studio.id) |> Repo.preload(:artists)
      assert from_db.name != attrs.name

      {:ok, studio} =
        Studios.update_studio_profile(
          studio,
          true,
          attrs
        )

      assert studio.name == "new name"
      assert studio.handle == "new-handle"
      assert studio.description == "new description"
      assert studio.summary == "new summary"
      assert studio.default_terms == "new terms"
      assert studio.default_template == "new template"

      from_db = Repo.get!(Studio, studio.id) |> Repo.preload(:artists)
      assert studio.name == from_db.name
      assert studio.handle == from_db.handle
      assert studio.description == from_db.description
      assert studio.summary == from_db.summary
      assert studio.default_terms == from_db.default_terms
      assert studio.default_template == from_db.default_template
    end

    test "update_stripe_state" do
      user = user_fixture()
      studio = studio_fixture([user])
      Studios.subscribe_to_stripe_state(studio)

      Studios.update_stripe_state!(studio.stripe_id, %Stripe.Account{
        charges_enabled: true,
        details_submitted: true
      })

      from_db = Repo.get!(Studio, studio.id)
      assert from_db.stripe_charges_enabled == true
      assert from_db.stripe_details_submitted == true

      topic = "studio_stripe_state:#{studio.stripe_id}"

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "charges_state_changed",
        payload: true
      }

      assert_receive %Phoenix.Socket.Broadcast{
        topic: ^topic,
        event: "details_submitted_changed",
        payload: true
      }

      Studios.unsubscribe_from_stripe_state(studio)
    end
  end

  describe "listing" do
    test "list all studios" do
      user = user_fixture()
      studio = studio_fixture([user])

      assert studio.id in Enum.map(Studios.list_studios(), & &1.id)
    end

    test "list user studios and studio members" do
      user = user_fixture()
      studio_handle = unique_studio_handle()
      studio_name = unique_studio_name()
      studio_url = "http://localhost:4000/studios/#{studio_handle}"

      Banchan.StripeAPI.Mock
      |> expect(:create_account, fn _ ->
        {:ok, %Stripe.Account{id: unique_stripe_id()}}
      end)

      {:ok, studio} =
        Banchan.Studios.new_studio(
          %Studio{artists: [user]},
          studio_url,
          valid_studio_attributes(%{
            name: studio_name,
            handle: studio_handle
          })
        )

      assert Enum.map(Studios.list_studios_for_user(user), & &1.id) == [studio.id]
      assert Enum.map(Studios.list_studio_members(studio), & &1.id) == [user.id]
      assert Studios.is_user_in_studio?(user, studio)
    end
  end

  describe "onboarding" do
    test "create onboarding link" do
      user = user_fixture()
      studio = studio_fixture([user])
      link_url = "http://link_url"

      Banchan.StripeAPI.Mock
      |> expect(:create_account_link, fn params ->
        assert %{
                 account: studio.stripe_id,
                 type: "account_onboarding",
                 return_url: "http://url1",
                 refresh_url: "http://url2"
               } == params

        {:ok, %Stripe.AccountLink{url: link_url}}
      end)

      assert Studios.get_onboarding_link!(studio, "http://url1", "http://url2") == link_url
    end
  end

  describe "charges and payouts" do
    test "charges_enabled?" do
      user = user_fixture()
      studio = studio_fixture([user])

      Studios.update_stripe_state!(studio.stripe_id, %Stripe.Account{
        charges_enabled: true
      })

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_account, fn _ ->
        {:ok, %Stripe.Account{charges_enabled: true}}
      end)

      assert !Studios.charges_enabled?(studio)
      assert Studios.charges_enabled?(studio, true)
    end

    test "basic payout" do
      commission = commission_fixture()
      client = commission.client
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      banchan_fee =
        amount
        |> Money.add(tip)
        |> Money.multiply(studio.platform_fee)

      net =
        amount
        |> Money.add(tip)
        |> Money.subtract(banchan_fee)
        |> Money.multiply(2)

      # Two successful invoices and one expired one
      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "please give me money :("
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "please give me money :("
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => Money.new(10_000, :USD),
          "text" => "please give me money :("
        })

      Commissions.expire_payment!(invoice, true)

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, 4, fn opts ->
        assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

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

      balance = Studios.get_banchan_balance!(studio)

      assert [net] == balance.stripe_available
      assert [Money.new(0, :USD)] == balance.stripe_pending
      assert [net] == balance.held_back
      assert [] == balance.released
      assert [] == balance.on_the_way
      assert [] == balance.paid
      assert [] == balance.available

      assert {:ok, []} == Studios.payout_studio(artist, studio)

      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :accepted)
      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :ready_for_review)
      {:ok, _} = Commissions.update_status(client, commission |> Repo.reload(), :approved)

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:create_payout, fn params, opts ->
        assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

        assert %{
                 amount: net.amount,
                 currency: "usd",
                 statement_descriptor: "banchan.art payout"
               } == params

        {:ok,
         %Stripe.Payout{
           id: stripe_payout_id,
           status: "pending",
           arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
           type: "card",
           method: "standard"
         }}
      end)

      {:ok, [%Payout{amount: ^net, status: :pending}]} = Studios.payout_studio(artist, studio)

      payout =
        from(p in Payout, where: p.studio_id == ^studio.id)
        |> Repo.one!()
        |> Repo.preload(:invoices)

      paid_invoices =
        from(i in Invoice,
          where: i.commission_id == ^commission.id and i.status == :succeeded,
          select: i.id
        )
        |> Repo.all()
        |> Enum.sort()

      assert paid_invoices == payout.invoices |> Enum.map(& &1.id) |> Enum.sort()

      expired_invoice =
        from(i in Invoice,
          where: i.commission_id == ^commission.id and i.status == :expired,
          select: i.id
        )
        |> Repo.one!()

      assert !Enum.find(payout.invoices, &(&1.id == expired_invoice))

      # Payout funds are marked as on_the_way until we get notified by stripe
      # that the payment has been completed.
      balance = Studios.get_banchan_balance!(studio)

      assert [net] == balance.stripe_available
      assert [Money.new(0, :USD)] == balance.stripe_pending
      assert [] == balance.held_back
      assert [] == balance.released
      assert [net] == balance.on_the_way
      assert [] == balance.paid
      assert [] == balance.available

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, 1, fn opts ->
        assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: 0
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

      Studios.process_payout_updated!(%Stripe.Payout{
        id: payout.stripe_payout_id,
        arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
        status: "paid",
        type: "card",
        method: "standard",
        failure_code: nil,
        failure_message: nil
      })

      balance = Studios.get_banchan_balance!(studio)

      assert [Money.new(0, :USD)] == balance.stripe_available
      assert [Money.new(0, :USD)] == balance.stripe_pending
      assert [] == balance.held_back
      assert [] == balance.released
      assert [] == balance.on_the_way
      assert [net] == balance.paid
      assert [] == balance.available
    end

    test "stripe pending vs released -> available" do
      commission = commission_fixture()
      client = commission.client
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      banchan_fee =
        amount
        |> Money.add(tip)
        |> Money.multiply(studio.platform_fee)

      net =
        amount
        |> Money.add(tip)
        |> Money.subtract(banchan_fee)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "please give me money :("
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, 4, fn opts ->
        assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: 0
             }
           ],
           # We've "released" funds from the commission, but the funds are
           # still pending their waiting period on stripe.
           pending: [
             %{
               currency: "usd",
               amount: net.amount
             }
           ]
         }}
      end)

      balance = Studios.get_banchan_balance!(studio)

      assert [Money.new(0, :USD)] == balance.stripe_available
      assert [net] == balance.stripe_pending
      assert [net] == balance.held_back
      assert [] == balance.released
      assert [] == balance.on_the_way
      assert [] == balance.paid
      assert [] == balance.available

      assert {:ok, []} == Studios.payout_studio(artist, studio)

      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :accepted)
      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :ready_for_review)
      {:ok, _} = Commissions.update_status(client, commission |> Repo.reload(), :approved)

      # No money available on Stripe yet, so no payout happens.
      assert {:ok, []} == Studios.payout_studio(artist, studio)

      balance = Studios.get_banchan_balance!(studio)

      assert [Money.new(0, :USD)] == balance.stripe_available
      assert [net] == balance.stripe_pending
      assert [] == balance.held_back
      assert [net] == balance.released
      assert [] == balance.on_the_way
      assert [] == balance.paid

      # This might be a bit weird, but it's fine, and we should always account for this case anyway.
      assert [Money.new(0, :USD)] == balance.available

      # Make them available!
      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, 1, fn opts ->
        assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

        {:ok,
         %Stripe.Balance{
           available: [
             %{
               currency: "usd",
               amount: net.amount
             }
           ],
           # We've "released" funds from the commission, but the funds are
           # still pending their waiting period on stripe.
           pending: [
             %{
               currency: "usd",
               amount: 0
             }
           ]
         }}
      end)

      # Payout funds are marked as on_the_way until we get notified by stripe
      # that the payment has been completed.
      balance = Studios.get_banchan_balance!(studio)

      assert [net] == balance.stripe_available
      assert [Money.new(0, :USD)] == balance.stripe_pending
      assert [] == balance.held_back
      assert [net] == balance.released
      assert [] == balance.on_the_way
      assert [] == balance.paid
      assert [net] == balance.available
    end

    test "immediate failed payout" do
      commission = commission_fixture()
      client = commission.client
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      banchan_fee =
        amount
        |> Money.add(tip)
        |> Money.multiply(studio.platform_fee)

      net =
        amount
        |> Money.add(tip)
        |> Money.subtract(banchan_fee)

      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "please give me money :("
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, 2, fn opts ->
        assert %{"Stripe-Account" => studio.stripe_id} == Keyword.get(opts, :headers)

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

      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :accepted)
      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :ready_for_review)
      {:ok, _} = Commissions.update_status(client, commission |> Repo.reload(), :approved)

      stripe_err = %Stripe.Error{
        source: %{},
        code: :amount_too_large,
        message: "Log me?",
        user_message: "Oops, something went wrong with your payout :("
      }

      Banchan.StripeAPI.Mock
      |> expect(:create_payout, fn _, _ ->
        # TODO: What are the actual possible value here? Need to test by hand. Sigh.
        # TODO: Assert that we're actually logging a message here
        {:error, stripe_err}
      end)

      {result, log} = with_log(fn -> Studios.payout_studio(artist, studio) end)
      assert {:error, stripe_err} == result
      assert log =~ "[error] Stripe error during payout: Log me?\n"

      [%Payout{status: :failed, stripe_payout_id: nil}] =
        from(p in Payout, where: p.studio_id == ^studio.id) |> Repo.all()

      # We don't mark them as failed when the failure was immediate. They just
      # stay "released".
      balance = Studios.get_banchan_balance!(studio)

      assert [net] == balance.stripe_available
      assert [Money.new(0, :USD)] == balance.stripe_pending
      assert [] == balance.held_back
      assert [net] == balance.released
      assert [] == balance.on_the_way
      assert [] == balance.paid
      assert [net] == balance.available
    end

    test "delayed payout failure" do
      commission = commission_fixture()
      client = commission.client
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      banchan_fee =
        amount
        |> Money.add(tip)
        |> Money.multiply(studio.platform_fee)

      net =
        amount
        |> Money.add(tip)
        |> Money.subtract(banchan_fee)

      # Two successful invoices and one expired one
      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "please give me money :("
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :accepted)
      {:ok, _} = Commissions.update_status(artist, commission |> Repo.reload(), :ready_for_review)
      {:ok, _} = Commissions.update_status(client, commission |> Repo.reload(), :approved)

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, 2, fn _ ->
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

      # Initial requests succeeded. Payout is now "pending"
      {:ok, [%Payout{amount: ^net, status: :pending} = payout]} =
        Studios.payout_studio(artist, studio)

      # TODO: Does your stripe available balance get drained in between
      # initial request and eventual failure?

      Studios.process_payout_updated!(%Stripe.Payout{
        id: payout.stripe_payout_id,
        arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
        status: "failed",
        failure_code: "account_closed",
        failure_message: "The bank account has been closed",
        type: "card",
        method: "standard"
      })

      balance = Studios.get_banchan_balance!(studio)

      assert [net] == balance.stripe_available
      assert [Money.new(0, :USD)] == balance.stripe_pending
      assert [] == balance.held_back
      assert [net] == balance.released
      assert [] == balance.on_the_way
      assert [] == balance.paid
      assert [net] == balance.available

      payout = payout |> Repo.reload()

      assert :failed == payout.status
      assert :account_closed == payout.failure_code
      assert "The bank account has been closed" == payout.failure_message
    end

    test "payout does not exist in our db yet (but might've been created already on Stripe" do
      assert_raise Ecto.NoResultsError, fn ->
        Studios.process_payout_updated!(%Stripe.Payout{
          id: "random-stripe-payout-id#{System.unique_integer()}",
          arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
          status: "canceled",
          failure_code: nil,
          failure_message: nil,
          type: "card",
          method: "standard"
        })
      end
    end

    test "canceled payout" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      banchan_fee =
        amount
        |> Money.add(tip)
        |> Money.multiply(studio.platform_fee)

      net =
        amount
        |> Money.add(tip)
        |> Money.subtract(banchan_fee)

      # Two successful invoices and one expired one
      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "please give me money :("
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      approve_commission(commission)

      stripe_payout_id = "stripe_payout_id#{System.unique_integer()}"

      Banchan.StripeAPI.Mock
      |> expect(:retrieve_balance, 2, fn _ ->
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

      # Initial requests succeeded. Payout is now "pending"
      {:ok, [%Payout{amount: ^net, status: :pending} = payout]} =
        Studios.payout_studio(artist, studio)

      assert :ok == Studios.cancel_payout(studio, payout.stripe_payout_id)

      payout = payout |> Repo.reload()

      # We don't update the status until Stripe tells us to.
      assert :pending == payout.status

      Studios.process_payout_updated!(%Stripe.Payout{
        id: payout.stripe_payout_id,
        status: "canceled",
        arrival_date: DateTime.utc_now() |> DateTime.to_unix(),
        type: "card",
        method: "standard",
        failure_code: nil,
        failure_message: nil
      })

      balance = Studios.get_banchan_balance!(studio)

      assert [net] == balance.stripe_available
      assert [Money.new(0, :USD)] == balance.stripe_pending
      assert [] == balance.held_back
      assert [net] == balance.released
      assert [] == balance.on_the_way
      assert [] == balance.paid
      assert [net] == balance.available

      payout = payout |> Repo.reload()

      assert :canceled == payout.status
    end

    test "payout cancellation error" do
      commission = commission_fixture()
      studio = commission.studio
      artist = Enum.at(studio.artists, 0)
      amount = Money.new(420, :USD)
      tip = Money.new(69, :USD)

      banchan_fee =
        amount
        |> Money.add(tip)
        |> Money.multiply(studio.platform_fee)

      net =
        amount
        |> Money.add(tip)
        |> Money.subtract(banchan_fee)

      # Two successful invoices and one expired one
      invoice =
        invoice_fixture(artist, commission, %{
          "amount" => amount,
          "text" => "please give me money :("
        })

      sess = checkout_session_fixture(invoice, tip)
      succeed_mock_payment!(sess)

      approve_commission(commission)

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

      {:ok, [%Payout{amount: ^net, status: :pending} = payout]} =
        Studios.payout_studio(artist, studio)

      log =
        capture_log([level: :debug], fn ->
          {:error,
           %Stripe.Error{
             source: :stripe
           }} = Studios.cancel_payout(studio, payout.stripe_payout_id)
        end)

      assert log =~ "internal message"
      assert log =~ "unknown_error"
    end
  end
end
