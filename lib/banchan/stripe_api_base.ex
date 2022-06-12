defmodule Banchan.StripeAPI.Base do
  @moduledoc """
  Wrapper behaviour for Stripe-related API calls. All calls to the Stripe API
  should be directed throuh here. This makes it possible to mock responses for
  unit testing.
  """
  @callback create_account(params :: %{}) ::
              {:ok, Stripe.Account.t()} | {:error, Stripe.Error.t()}
  @callback retrieve_account(id :: Stripe.id()) ::
              {:ok, Stripe.Account.t()} | {:error, Stripe.Error.t()}
  @callback create_account_link(params :: %{}) ::
              {:ok, Stripe.AccountLink.t()} | {:error, Stripe.Error.t()}
  @callback retrieve_balance(opts :: Stripe.options()) ::
              {:ok, Stripe.Balance.t()} | {:error, Stripe.Error.t()}
  @callback create_payout(params :: %{}, opts :: Stripe.options()) ::
              {:ok, Stripe.Payout.t()} | {:error, Stripe.Error.t()}
  @callback cancel_payout(payout :: Stripe.id(), opts :: Stripe.options()) ::
              {:ok, Stripe.Payout.t()} | {:error, Stripe.Error.t()}
  @callback create_session(params :: Stripe.Session.create_params()) ::
              {:ok, Stripe.Session.t()} | {:error, Stripe.Error.t()}
  @callback retrieve_payment_intent(
              intent :: Stripe.id() | Stripe.PaymentIntent.t(),
              params :: %{},
              Stripe.options()
            ) :: {:ok, Stripe.PaymentIntent.t()} | {:error, Stripe.Error.t()}
  @callback retrieve_balance_transaction(id :: Stripe.id(), opts :: Stripe.options()) ::
              {:ok, Stripe.BalanceTransaction.t()} | {:error, Stripe.Error.t()}
  @callback expire_payment(id :: Stripe.id()) :: :ok | {:error, Stripe.Error.t()}
  @callback construct_webhook_event(
              raw_body :: String.t(),
              signature :: String.t(),
              endpoint_secret :: String.t()
            ) :: {:ok, Stripe.Event.t()} | {:error, Stripe.Error.t()}
  @callback create_refund(params :: %{}, opts :: Stripe.options()) ::
              {:ok, Stripe.Refund.t()} | {:error, Stripe.Error.t()}
  @callback retrieve_session(id :: Stripe.id(), opts :: Stripe.options()) ::
              {:ok, Stripe.Session.t()} | {:error, Stripe.Error.t()}
end
