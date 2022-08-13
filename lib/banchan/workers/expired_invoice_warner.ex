defmodule Banchan.Workers.ExpiredInvoiceWarner do
  @moduledoc """
  Warns studio members (and maybe clients) that their invoices are about to
  expire and be purged if they don't take action. This is separate from the
  actual purging, which is handled by Banchan.Workers.ExpiredInvoices.
  """
end
