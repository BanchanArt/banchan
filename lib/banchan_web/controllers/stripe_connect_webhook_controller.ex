defmodule BanchanWeb.StripeConnectWebhookController do
  @moduledoc """
  Handles Stripe Connect-related webhooks
  """
  use BanchanWeb, :controller

  alias Banchan.Studios

  def webhook(conn, _params) do
    [sig] = get_req_header(conn, "stripe-signature")

    {:ok, %Stripe.Event{} = event} =
      Stripe.Webhook.construct_event(
        conn.assigns.raw_body,
        sig,
        Application.fetch_env!(:stripity_stripe, :endpoint_secret)
      )

    handle_event(conn, event)
  end

  defp handle_event(conn, %Stripe.Event{type: "account.updated"} = event) do
    Studios.update_stripe_charges_enabled(event.account, event.data.object.charges_enabled)

    conn
    |> resp(200, "OK")
    |> send_resp()
  end
end
