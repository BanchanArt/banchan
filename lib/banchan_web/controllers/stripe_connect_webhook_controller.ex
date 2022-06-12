defmodule BanchanWeb.StripeConnectWebhookController do
  @moduledoc """
  Handles Stripe Connect-related webhooks
  """
  use BanchanWeb, :controller

  require Logger

  alias Banchan.Commissions
  alias Banchan.Studios

  def webhook(conn, _params) do
    [sig] = get_req_header(conn, "stripe-signature")

    {:ok, %Stripe.Event{} = event} =
      stripe_mod().construct_webhook_event(
        conn.assigns.raw_body,
        sig,
        Application.fetch_env!(:stripity_stripe, :endpoint_secret)
      )

    handle_event(event, conn)
  end

  defp handle_event(%Stripe.Event{type: "account.updated"} = event, conn) do
    Studios.update_stripe_state!(event.account, event.data.object)

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: "checkout.session.completed"} = event, conn) do
    if event.data.object.payment_status == "paid" do
      Commissions.process_payment_succeeded!(event.data.object)
    end

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: "checkout.session.expired"} = event, conn) do
    Commissions.process_payment_expired!(event.data.object)

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: "payout." <> type} = event, conn) do
    Logger.debug("Got a new payout event of type payout.#{type}. Updating database.")
    Studios.process_payout_updated!(event.data.object)

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: "charge.refund.updated"} = event, conn) do
    {:ok, _} = Commissions.process_refund_updated(event.data.object, nil)

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{type: type}, conn) do
    Logger.debug("unhandled_event: #{type}")

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp stripe_mod do
    Application.get_env(:banchan, :stripe_mod)
  end
end
