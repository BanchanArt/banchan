defmodule BanchanWeb.FuckAiPlug do
  @moduledoc """
  Tells AI crawlers to stay the fuck away, for what it's worth.
  """
  import Plug.Conn

  @doc false
  @spec init(any()) :: any()
  def init(config), do: config

  @doc false
  def call(conn, _) do
    conn
    |> put_resp_header("x-robots-tag", "noai")
  end
end
