defmodule Banchan.Workers.UploadDeleter do
  @moduledoc """
  Worker responsible for deleting uploads and cleaning up their associated backing data.
  """
  use Oban.Worker,
    queue: :upload_cleanup,
    unique: [period: 60],
    tags: ["media", "cleanup", "uploads"]

  alias Banchan.Repo
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  @impl Oban.Worker
  def perform(%_{args: %{"id" => id}}) do
    Uploads.delete_upload(%Upload{id: id} |> Repo.reload())
  end

  def schedule_deletion(%Upload{} = upload) do
    __MODULE__.new(%{"id" => upload.id})
    |> Oban.insert()
  end
end
