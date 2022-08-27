defmodule Banchan.Workers.Pruner do
  @moduledoc """
  Worker that takes care of pruning data slated for deletion which was
  soft-deleted. This includes Users, Studios, Offerings, etc.
  """
  use Oban.Worker,
    queue: :pruning,
    unique: [period: 60],
    tags: ["deletion", "pruning"]

  alias Banchan.{Accounts, Offerings, Repo, Studios}

  def perform(_) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:prune_users, fn _, _ -> Accounts.prune_users() end)
    |> Ecto.Multi.run(:prune_studios, fn _, _ -> Studios.prune_studios() end)
    |> Ecto.Multi.run(:prune_offerings, fn _, _ -> Offerings.prune_offerings() end)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> :ok
      {:error, _, error, _} -> {:error, error}
    end
  end
end
