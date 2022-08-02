defmodule BanchanWeb.BasicAuthPlug do
  @moduledoc """
  Applies basic auth if it's been configured
  """
  @doc false
  @spec init(any()) :: any()
  def init(opts), do: opts

  @doc false
  def call(conn, nil) do
    conn
  end

  def call(conn, opts) do
    Plug.BasicAuth.basic_auth(conn, opts)
  end
end
