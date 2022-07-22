defmodule Banchan.Workers.EnableStudio do
  @moduledoc """
  Re-enables studios after a certain amount of time has passed.
  """
  use Oban.Worker,
    queue: :unban,
    unique: [period: 60],
    max_attempts: 5,
    tags: ["unban", "unban-studio"]

  alias Banchan.Studios

  @impl Oban.Worker
  def perform(%_{args: %{"studio_id" => studio_id}}) do
    Studios.enable_studio(nil, %Studios.Studio{id: studio_id}, "ban expired", false)
  end

  def schedule_unban(%Studios.Studio{} = studio, disabled_until) do
    %{studio_id: studio.id}
    |> __MODULE__.new(scheduled_at: disabled_until)
    |> Oban.insert()
  end

  def cancel_unban(%Studios.StudioDisableHistory{} = history) do
    if history.lifting_job_id do
      Oban.cancel_job(history.lifting_job_id)
    end
  end
end
