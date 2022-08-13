defmodule Banchan.Workers.ExpiredInvoices do
  @moduledoc """
  Takes care of purging expired invoices that haven't been either refunded or
  paid out, based on how long we're able to hold on to the money.
  """
end
