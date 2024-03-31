defmodule Banchan.Workers.UploadDeleter do
  @moduledoc """
  Worker responsible for deleting uploads and cleaning up their associated backing data.
  """
  use Oban.Worker,
    queue: :pruning,
    unique: [period: 60],
    max_attempts: 3,
    tags: ["media", "pruning", "uploads"]

  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  @impl Oban.Worker
  def perform(%_{args: %{"id" => id, "bucket" => bucket, "key" => key}}) do
    if is_nil(Uploads.get_by_id(id)) do
      Uploads.delete_data!(%Upload{id: id, bucket: bucket, key: key})
    end

    :ok
  end

  def queue_data_deletion(%Upload{} = upload) do
    __MODULE__.new(%{
      "id" => upload.id,
      "bucket" => upload.bucket,
      "key" => upload.key
    })
    |> Oban.insert()
  end
end
