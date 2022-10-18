defmodule Banchan.StripeAPI do
  @moduledoc """
  Base implementation for Banchan.StripeAPI.Base behavior
  """
  @behaviour Banchan.StripeAPI.Base

  @impl Banchan.StripeAPI.Base
  def create_account(params) do
    Stripe.Account.create(params)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_account(id) do
    Stripe.Account.retrieve([account: id])
  end

  @impl Banchan.StripeAPI.Base
  def create_account_link(params) do
    Stripe.AccountLink.create(params)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_balance(opts \\ []) do
    Stripe.Balance.retrieve(opts)
  end

  @impl Banchan.StripeAPI.Base
  def create_payout(params, opts) do
    Stripe.Payout.create(params, opts)
  end

  @impl Banchan.StripeAPI.Base
  def cancel_payout(id, opts) do
    Stripe.Payout.cancel(id, opts)
  end

  @impl Banchan.StripeAPI.Base
  def create_session(params) do
    Stripe.Session.create(params)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_payment_intent(intent, params, opts \\ []) do
    Stripe.PaymentIntent.retrieve(intent, params, opts)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_balance_transaction(id, opts) do
    Stripe.BalanceTransaction.retrieve(id, opts)
  end

  @impl Banchan.StripeAPI.Base
  def expire_payment(session_id) do
    Stripe.Session.expire(session_id)
  end

  @impl Banchan.StripeAPI.Base
  def construct_webhook_event(raw_body, signature, endpoint_secret) do
    Stripe.Webhook.construct_event(raw_body, signature, endpoint_secret)
  end

  @impl Banchan.StripeAPI.Base
  def create_refund(params, opts) do
    Stripe.Refund.create(params, opts)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_session(id, opts) do
    Stripe.Session.retrieve(id, opts)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_transfer(id) do
    Stripe.Transfer.retrieve(id, expand: ["destination_payment.balance_transaction"])
  end

  @impl Banchan.StripeAPI.Base
  def update_account(id, params) do
    Stripe.Account.update(id, params)
  end

  @impl Banchan.StripeAPI.Base
  def create_login_link(id, params) do
    Stripe.LoginLink.create(id, params)
  end

  @impl Banchan.StripeAPI.Base
  def delete_account(id) do
    Stripe.Account.delete(id)
  end

  @impl Banchan.StripeAPI.Base
  def create_price(params) do
    Stripe.Price.create(params)
  end

  @impl Banchan.StripeAPI.Base
  def retrieve_charge(id) do
    Stripe.Charge.retrieve(id, expand: ["balance_transaction"])
  end

  @impl Banchan.StripeAPI.Base
  def create_apple_pay_domain(id, domain) do
    Stripe.API.request(%{domain_name: domain}, :post, "apple_pay/domains", %{},
      connect_account: id
    )
  end
end
