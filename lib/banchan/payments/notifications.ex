defmodule Banchan.Payments.Notifications do
  @moduledoc """
  Send notifications related to payments.
  """

  alias Banchan.Accounts.User
  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, Event}
  alias Banchan.Notifications
  alias Banchan.Payments.{Invoice, Payout}
  alias Banchan.Repo
  alias Banchan.Workers.Mailer

  # Unfortunate, but needed for crafting URLs for notifications
  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  @pubsub Banchan.PubSub

  @doc """
  Broadcasts payout state updates.
  """
  def payout_updated(%Payout{} = payout, _actor \\ nil) do
    Notifications.with_task(fn ->
      Phoenix.PubSub.broadcast!(
        @pubsub,
        "payout:#{payout.studio.handle}",
        %Phoenix.Socket.Broadcast{
          topic: "payout:#{payout.studio.handle}",
          event: "payout_updated",
          payload: payout
        }
      )
    end)
  end

  @doc """
  Emails an invoice receipt.
  """
  def send_receipt(%Invoice{} = invoice, %User{} = client, %Commission{} = commission) do
    Mailer.new_email(
      client.email,
      "Banchan Art Receipt for #{commission.title}",
      BanchanWeb.Email.CommissionsView,
      :receipt,
      invoice: invoice |> Repo.preload([:event]),
      commission: commission |> Repo.preload([:line_items]),
      deposited: Commissions.deposited_amount(client, commission, true),
      tipped: Commissions.tipped_amount(client, commission, true)
    )
    |> Mailer.deliver()
  end

  @doc """
  Sends out web/email notifications only, when a refund in a commission has
  its status updated (when it succeeds, fails, etc)
  """
  def invoice_refund_updated(%Commission{} = commission, %Event{} = event, actor \\ nil) do
    # No need for a broadcast. That's already being handled by commission_event_updated
    Notifications.with_task(fn ->
      {:ok, _} =
        Repo.transaction(fn ->
          subs = Commissions.Notifications.subscribers(commission)

          url =
            Routes.commission_url(Endpoint, :show, commission.public_id)
            |> replace_fragment(event)

          body = refund_updated_body(event.invoice.refund_status)
          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            subs,
            %Notifications.UserNotification{
              type: "invoice_refunded",
              title: commission.title,
              short_body: body,
              text_body: "#{body}\n\n#{url}",
              html_body: "<p>#{body}</p><p><a href=\"#{safe_url}\">View it</a></p>",
              url: url,
              read: false
            },
            is_reply: true
          )
        end)
    end)
  end

  defp refund_updated_body(refund_status)

  defp refund_updated_body(:pending) do
    "A refund has been submitted and is currently pending."
  end

  defp refund_updated_body(:succeeded) do
    raise "This event should be getting handled by new_commission_event instead."
  end

  defp refund_updated_body(:failed) do
    "A refund attempt has failed."
  end

  defp refund_updated_body(:canceled) do
    "A refund has been canceled."
  end

  defp refund_updated_body(:requires_action) do
    "A refund requires further action."
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end
end
