defmodule Banchan.Workers.EnableUser do
  @moduledoc """
  Re-enables users after a certain amount of time has passed.
  """
  use Oban.Worker,
    queue: :unban,
    unique: [period: 60],
    max_attempts: 5,
    tags: ["unban", "unban-user"]

  alias Banchan.Accounts

  @impl Oban.Worker
  def perform(%_{args: %{"user_id" => user_id}}) do
    Accounts.enable_user(
      Accounts.system_user(),
      %Accounts.User{id: user_id},
      "ban expired",
      false
    )
  end

  def schedule_unban(%Accounts.User{} = user, disabled_until) do
    %{user_id: user.id}
    |> __MODULE__.new(scheduled_at: disabled_until)
    |> Oban.insert()
  end

  def cancel_unban(%Accounts.DisableHistory{} = history) do
    if history.lifting_job_id do
      Oban.cancel_job(history.lifting_job_id)
    end
  end
end
