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
  def perform(%_{args: %{"id" => id, "keep_original" => keep_original}}) do
    upload = Uploads.get_by_id(id)

    if is_nil(upload) do
      :ok
    else
      refreshed_upload =
        if keep_original || !upload.original_id do
          {:ok, upload}
        else
          with {:ok, _} <- Uploads.delete_upload(Uploads.get_by_id(upload.original_id)) do
            {:ok, Uploads.get_by_id(id)}
          end
        end

      with {:ok, %Upload{} = upload} <- refreshed_upload do
        Uploads.delete_upload(upload)
      end
    end
  end

  def schedule_deletion(%Upload{} = upload, opts \\ []) do
    __MODULE__.new(%{
      "id" => upload.id,
      "keep_original" => Keyword.get(opts, :keep_original, false)
    })
    |> Oban.insert()
  end
end
