defmodule Banchan.Workers.ExpiredInvoiceWarner do
  @moduledoc """
  Warns studio members (and maybe clients) that their invoices are about to
  expire and be purged if they don't take action. This is separate from the
  actual purging, which is handled by Banchan.Workers.ExpiredInvoices.
  """
  use Oban.Worker,
    queue: :invoice_purge,
    unique: [period: 60],
    max_attempts: 5,
    tags: ["invoices", "warning", "notification"]

  alias Banchan.Payments.Invoice
  alias Banchan.Payments.Notifications

  @impl Oban.Worker
  def perform(%_{args: %{"invoice_id" => invoice_id}}) do
    Notifications.invoice_expiry_warning(%Invoice{id: invoice_id})
  end

  def schedule_warning(%Invoice{} = invoice, %DateTime{} = warn_on) do
    %{invoice_id: invoice.id}
    |> __MODULE__.new(scheduled_at: warn_on)
    |> Oban.insert()
  end
end
