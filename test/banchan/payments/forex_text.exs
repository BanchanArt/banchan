defmodule Banchan.PaymentsTest.Forex do
  @moduledoc """
  Tests for foreign exchange rate and conversion functionality.
  """
  use Banchan.DataCase

  import Mox

  alias Ecto.Adapters.SQL.Sandbox

  alias Banchan.Notifications
  alias Banchan.Payments

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    on_exit(fn -> Notifications.wait_for_notifications() end)

    forex = Process.whereis(Banchan.Payments.Forex)
    Sandbox.allow(Banchan.Repo, self(), forex)

    Payments.clear_exchange_rates(:USD)
    Payments.clear_exchange_rates(:JPY)
    Payments.clear_exchange_rates(:EUR)
    %{}
  end

  describe "get_exchange_rate/2" do
    test "returns 1.0 for the same currency pair without doing any requests" do
      assert Payments.get_exchange_rate(:USD, :USD) == 1.0
    end

    test "returns nil if an exchange rate couldn't be found" do
      Banchan.Http.Mock
      |> expect(:get, 1, fn "https://api.exchangerate.host/latest?base=USD" ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!(%{
               "rates" => %{
                 "EUR" => 0.913,
                 "JPY" => 142.833
               }
             })
         }}
      end)

      assert Payments.get_exchange_rate(:USD, :CAD) == nil
    end

    test "returns the exchange rate for the given currency pair" do
      Banchan.Http.Mock
      |> expect(:get, 1, fn "https://api.exchangerate.host/latest?base=USD" ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!(%{
               "rates" => %{
                 "EUR" => 0.913,
                 "JPY" => 142.833
               }
             })
         }}
      end)

      assert Payments.get_exchange_rate(:USD, :JPY) == 142.833

      # Only one request is made, since we already have all the USD exchange rates.
      assert Payments.get_exchange_rate(:USD, :EUR) == 0.913

      # Order matters.
      Banchan.Http.Mock
      |> expect(:get, 1, fn "https://api.exchangerate.host/latest?base=JPY" ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!(%{
               "rates" => %{
                 "USD" => 0.007081,
                 "EUR" => 0.006431
               }
             })
         }}
      end)

      assert Payments.get_exchange_rate(:JPY, :USD) == 0.007081
      assert Payments.get_exchange_rate(:JPY, :EUR) == 0.006431
    end
  end

  describe "cmp_money/2" do
    test "returns :eq without getting exchange rates if both Moneys are equal and same currency" do
      assert Payments.cmp_money(Money.new(100, :USD), Money.new(100, :USD)) == :eq
    end

    test "doesn't get exchange rates if currencies are the same" do
      assert Payments.cmp_money(Money.new(10, :USD), Money.new(100, :USD)) == :lt
      assert Payments.cmp_money(Money.new(100, :USD), Money.new(10, :USD)) == :gt
    end

    test "if currencies differ, the first's exchange rates are used to convert the latter" do
      Banchan.Http.Mock
      |> expect(:get, 1, fn "https://api.exchangerate.host/latest?base=USD" ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!(%{
               "rates" => %{
                 "JPY" => 142.833
               }
             })
         }}
      end)

      assert Payments.cmp_money(Money.new(100, :USD), Money.new(100, :JPY)) == :gt
      # Only one request is made
      assert Payments.cmp_money(Money.new(100, :USD), Money.new(100_000, :JPY)) == :lt

      # Order matters.
      Banchan.Http.Mock
      |> expect(:get, 1, fn "https://api.exchangerate.host/latest?base=JPY" ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body:
             Jason.encode!(%{
               "rates" => %{
                 "USD" => 0.007081
               }
             })
         }}
      end)

      assert Payments.cmp_money(Money.new(100, :JPY), Money.new(100, :USD)) == :lt
      # Only one request is made
      assert Payments.cmp_money(Money.new(100_000, :JPY), Money.new(100, :USD)) == :gt
    end
  end

  describe "convert_money/2" do
  end
end
