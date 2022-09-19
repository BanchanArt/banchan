defmodule BanchanWeb.StripeConnectWebhookController do
  @moduledoc """
  Handles Stripe Connect-related webhooks
  """
  use BanchanWeb, :controller

  require Logger

  alias Banchan.Studios

  def webhook(conn, _params) do
    [sig] = get_req_header(conn, "stripe-signature")

    {:ok, %Stripe.Event{} = event} =
      stripe_mod().construct_webhook_event(
        conn.assigns.raw_body,
        sig,
        Application.fetch_env!(:stripity_stripe, :connect_webhook_secret)
      )

    handle_event(event, conn)
  end

  defp handle_event(%Stripe.Event{type: "account.updated"} = event, conn) do
    Studios.update_stripe_state!(event.data.object.id, event.data.object)

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
