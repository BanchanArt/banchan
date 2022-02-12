defmodule BanchanWeb.CacheBodyReader do
  @moduledoc """
  Caches the body of a request in the conn.assigns.

  Used for making sure, for example, that we have access to the raw JSON string for JSON requests.
  """

  # TODO: Is this really what we want to do to enable request verification for Stripe?
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end
end
