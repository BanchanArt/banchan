defmodule Banchan.Http.Base do
  @moduledoc """
  Wrapper around HTTPoison-like interface to enable mocking.
  """
  @callback get(String.t()) :: {:ok, HTTPoison.Response.t()} | {:error, HTTPoison.Response.t()}
end
