defmodule Banchan.Identities do
  @moduledoc """
  The Identities context.
  """
  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Studios.Studio

  def get_user_or_studio_by_handle(handle) do
    cond do
      user = Repo.get_by(User, handle: handle) -> {:ok, user}
      studio = Repo.get_by(Studio, handle: handle) -> {:ok, studio}
      true -> {:error, not_found_message(handle)}
    end
  end

  def validate_uniqueness_of_handle(handle) do
    msg = not_found_message(handle)

    case get_user_or_studio_by_handle(handle) do
      {:ok, _} -> false
      {:error, ^msg} -> true
    end
  end

  defp not_found_message(handle) do
    "No user or studio found for: #{handle}"
  end
end
