defmodule Banchan.Workers.UploadDeleter do
  @moduledoc """
  Worker responsible for deleting uploads and cleaning up their associated backing data.
  """
  use Oban.Worker,
    queue: :upload_cleanup,
    unique: [period: 60],
    tags: ["media", "cleanup", "uploads"]

  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  @impl Oban.Worker
  def perform(%_{args: %{"id" => id, "delete_original" => delete_original}}) do
    upload = Uploads.get_by_id!(id)

    original =
      if delete_original && upload.original_id do
        Uploads.delete_upload(Uploads.get_by_id!(upload.original_id))
      else
        {:ok, nil}
      end

    with {:ok, _} <- original do
      Uploads.delete_upload(upload)
    end
  end

  def schedule_deletion(%Upload{} = upload, opts \\ []) do
    __MODULE__.new(%{
      "id" => upload.id,
      "delete_original" => Keyword.get(opts, :delete_original, false)
    })
    |> Oban.insert()
  end
end
