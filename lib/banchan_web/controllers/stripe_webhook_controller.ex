defmodule BanchanWeb.StripeWebhookController do
  @moduledoc """
  Handles Stripe platform account-level webhooks.
  """
  use BanchanWeb, :controller

  require Logger

  alias Banchan.Accounts
  alias Banchan.Payments

  def webhook(conn, _params) do
    [sig] = get_req_header(conn, "stripe-signature")

    {:ok, %Stripe.Event{} = event} =
      stripe_mod().construct_webhook_event(
        conn.assigns.raw_body,
        sig,
        Application.fetch_env!(:stripity_stripe, :webhook_secret)
      )

    handle_event(event, conn)
  end

  defp handle_event(%Stripe.Event{type: "checkout.session.completed"} = event, conn) do
    if event.data.object.payment_status == "paid" do
      Payments.process_payment_succeeded!(event.data.object)
    end

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: "checkout.session.expired"} = event, conn) do
    Payments.process_payment_expired!(event.data.object)

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: "charge.refund.updated"} = event, conn) do
    {:ok, _} = Payments.process_refund_updated(Accounts.system_user(), event.data.object, nil)

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: type}, conn) do
    Logger.info("unhandled_event: #{type}")

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp stripe_mod do
    Application.get_env(:banchan, :stripe_mod)
  end
end
