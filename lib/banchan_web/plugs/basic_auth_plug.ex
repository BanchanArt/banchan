defmodule BanchanWeb.BasicAuthPlug do
  @moduledoc """
  Applies basic auth if it's been configured
  """
  @doc false
  @spec init(any()) :: any()
  def init(opts), do: opts

  @doc false
  def call(conn, _) do
    case Application.get_env(:banchan, :basic_auth) do
      nil ->
        conn

      opts ->
        Plug.BasicAuth.basic_auth(conn, opts)
    end
  end
end
