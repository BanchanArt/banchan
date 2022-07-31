defmodule Banchan.Workers.Pruner do
  @moduledoc """
  Worker that takes care of pruning data slated for deletion which was
  soft-deleted. This includes Users, Studios, Offerings, etc.
  """
  use Oban.Worker,
    queue: :pruning,
    unique: [period: 60],
    tags: ["deletion", "pruning"]

  alias Banchan.{Accounts, Commissions, Repo, Studios}

  def perform(_) do
    {:ok, ret} =
      Repo.transaction(fn ->
        Accounts.prune_users()
        Studios.prune_studios()
        Commissions.prune_offerings()
        :ok
      end)

    ret
  end
end
