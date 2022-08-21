defmodule Banchan.Workers.ExpiredInvoicePurger do
  @moduledoc """
  Takes care of purging expired invoices that haven't been either refunded or
  paid out, based on how long we're able to hold on to the money.
  """
  use Oban.Worker,
    queue: :invoice_purge,
    unique: [period: 60],
    max_attempts: 5,
    tags: ["invoices", "purge", "doomsday"]

  alias Banchan.Payments
  alias Banchan.Payments.Invoice

  @impl Oban.Worker
  def perform(%_{args: %{"invoice_id" => invoice_id}}) do
    Payments.purge_expired_invoice(%Invoice{id: invoice_id})
  end

  def schedule_purge(%Invoice{} = invoice, %DateTime{} = purge_on) do
    %{invoice_id: invoice.id}
    |> __MODULE__.new(scheduled_at: purge_on)
    |> Oban.insert()
  end
end
