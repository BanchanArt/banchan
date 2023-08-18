defmodule BanchanWeb.Redirect do
  @moduledoc """
  A Plug to allow for easily doing redirects within a Plug or Phoenix router.

  Based on code found at:
    https://www.viget.com/articles/how-to-redirect-from-the-phoenix-router/
  """

  def init(opts) do
    if Keyword.has_key?(opts, :to) || Keyword.has_key?(opts, :external) do
      opts
    else
      raise("Missing required option ':to' in redirect")
    end
  end

  def call(conn, opts) do
    conn
    |> Phoenix.Controller.redirect(opts)
  end
end
