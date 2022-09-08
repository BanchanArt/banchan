defmodule Banchan.Payments.Notifications do
  @moduledoc """
  Send notifications related to payments.
  """

  alias Banchan.Accounts
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
  Notifies studio members that a payout is on its way.
  """
  def payout_sent(%Payout{} = payout) do
    Notifications.with_task(fn ->
      {:ok, _} =
        Repo.transaction(fn ->
          actor = Accounts.system_user()

          payout =
            payout |> Repo.reload() |> Repo.preload(studio: [artists: [:notification_settings]])

          body =
            "A payout for #{Money.to_string(payout.amount)} is on its way to your bank account."

          url = Routes.studio_payouts_url(Endpoint, :show, payout.studio.handle, payout.public_id)

          {:safe, safe_url} = Phoenix.HTML.html_escape(url)

          Notifications.notify_subscribers!(
            actor,
            payout.studio.artists,
            %Notifications.UserNotification{
              type: "payout_sent",
              title: "Payout on the way!",
              short_body: body,
              text_body: "#{body}\n\n#{url}",
              html_body: "<p>#{body}</p><p><a href=\"#{safe_url}\">View it</a></p>",
              url: url,
              read: false
            }
          )
        end)
    end)
  end

  @doc """
  Sends a warning that an invoice is about to expire and must either be paid
  out or reimbursed, or the system will do it automatically.
  """
  def invoice_expiry_warning(%Invoice{} = invoice) do
    # We don't shove this in a separate task because this one is meant to be
    # handled by an actual Oban Worker.
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = Accounts.system_user()

        invoice =
          invoice
          |> Repo.reload()
          |> Repo.preload([:event, commission: [studio: [artists: [:notification_settings]]]])

        body =
          "An invoice payment for #{invoice.total_transferred} is expiring in 72 hours. Unreleased expired payments will be reimbursed to the client automatically."

        url =
          Routes.commission_url(Endpoint, :show, invoice.commission.public_id)
          |> replace_fragment(invoice.event)

        {:safe, safe_url} = Phoenix.HTML.html_escape(url)

        Notifications.notify_subscribers!(
          actor,
          invoice.commission.studio.artists,
          %Notifications.UserNotification{
            type: "invoice_expiring_soon",
            title: "Invoice payment expiring soon",
            short_body: body,
            text_body: "#{body}\n\n#{url}",
            html_body: "<p>#{body}</p><p><a href=\"#{safe_url}\">View it</a></p>",
            url: url,
            read: false
          }
        )
      end)

    ret
  end

  @doc """
  Lets both the client and the studio members know that a paid invoice has
  been refunded due to expiring.
  """
  def expired_invoice_refunded(%Invoice{} = invoice) do
    # We don't shove this in a separate task because this one is meant to be
    # handled by an actual Oban Worker.
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = Accounts.system_user()

        invoice =
          invoice
          |> Repo.reload()
          |> Repo.preload([
            :event,
            commission: [
              client: [:notification_settings],
              studio: [artists: [:notification_settings]]
            ]
          ])

        body =
          "An invoice payment for #{invoice.total_transferred} has expired and has been refunded. Please initiate a new payment."

        url =
          Routes.commission_url(Endpoint, :show, invoice.commission.public_id)
          |> replace_fragment(invoice.event)

        {:safe, safe_url} = Phoenix.HTML.html_escape(url)

        Notifications.notify_subscribers!(
          actor,
          [invoice.commission.client | invoice.commission.studio.artists],
          %Notifications.UserNotification{
            type: "expired_invoice_refunded",
            title: "Expired invoice refunded",
            short_body: body,
            text_body: "#{body}\n\n#{url}",
            html_body: "<p>#{body}</p><p><a href=\"#{safe_url}\">View it</a></p>",
            url: url,
            read: false
          }
        )
      end)

    ret
  end

  @doc """
  Lets studio members know that a payout for an expired invoice has been
  automatically created for them.
  """
  def expired_invoice_paid_out(%Invoice{} = invoice) do
    # We don't shove this in a separate task because this one is meant to be
    # handled by an actual Oban Worker.
    {:ok, ret} =
      Repo.transaction(fn ->
        actor = Accounts.system_user()

        invoice =
          invoice
          |> Repo.reload()
          |> Repo.preload([:event, commission: [studio: [artists: [:notification_settings]]]])

        body =
          "An invoice payment for #{invoice.total_transferred} has expired and a payout has been automatically initiated for it."

        url =
          Routes.commission_url(Endpoint, :show, invoice.commission.public_id)
          |> replace_fragment(invoice.event)

        {:safe, safe_url} = Phoenix.HTML.html_escape(url)

        Notifications.notify_subscribers!(
          actor,
          invoice.commission.studio.artists,
          %Notifications.UserNotification{
            type: "expired_invoice_paid_out",
            title: "Expired invoice paid out",
            short_body: body,
            text_body: "#{body}\n\n#{url}",
            html_body: "<p>#{body}</p><p><a href=\"#{safe_url}\">View it</a></p>",
            url: url,
            read: false
          }
        )
      end)

    ret
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
