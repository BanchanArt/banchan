defmodule BanchanWeb.StripeConnectWebhookController do
  @moduledoc """
  Handles Stripe Connect-related webhooks
  """
  use BanchanWeb, :controller

  alias Banchan.Studios

  @pubsub Banchan.PubSub

  def webhook(conn, _params) do
    [sig] = get_req_header(conn, "stripe-signature")

    {:ok, %Stripe.Event{} = event} =
      Stripe.Webhook.construct_event(
        conn.assigns.raw_body,
        sig,
        Application.fetch_env!(:stripity_stripe, :endpoint_secret)
      )

    handle_event(event, conn)
  end

  defp handle_event(%Stripe.Event{type: "account.updated"} = event, conn) do
    Studios.update_stripe_charges_enabled(event.account, event.data.object.charges_enabled)

    Phoenix.PubSub.broadcast!(
      @pubsub,
      "studio_stripe_state:#{event.account}",
      %{event: "charges_state_changed", payload: event.data.object.charges_enabled}
    )

    conn
    |> resp(200, "OK")
    |> send_resp()
  end

  defp handle_event(%Stripe.Event{}, conn) do
    # TODO: Do we want to log anything about events we got that we're not handling?
    conn
    |> resp(200, "OK")
    |> send_resp()
  end
end
