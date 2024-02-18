defmodule Banchan.Workers.Pruner do
  @moduledoc """
  Worker that takes care of pruning data slated for deletion which was
  soft-deleted. This includes Users, Studios, Offerings, etc.
  """
  use Oban.Worker,
    queue: :pruning,
    unique: [period: 60],
    tags: ["deletion", "pruning"]

  require Logger

  alias Banchan.{Accounts, Offerings, Repo, Studios, Uploads}

  def perform(_) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:pruned_users, fn _, _ -> Accounts.prune_users() end)
    |> Ecto.Multi.run(:pruned_studios, fn _, _ -> Studios.prune_studios() end)
    |> Ecto.Multi.run(:pruned_offerings, fn _, _ -> Offerings.prune_offerings() end)
    |> Ecto.Multi.run(:pruned_uploads, fn _, _ -> Uploads.prune_uploads() end)
    |> Repo.transaction()
    |> case do
      {:ok, stats} ->
        Logger.info("Prune job completed successfully: #{inspect(stats)}")
        :ok

      {:error, _, error, _} ->
        {:error, error}
    end
  end
end
