defmodule Banchan.Http do
  @moduledoc """
  Main implementation for Banchan.Http.Base behaviour
  """
  @behaviour Banchan.Http.Base

  @impl Banchan.Http.Base
  def get(url) do
    HTTPoison.get(url)
  end
end
