defmodule Banchan.Uploads do
  alias Banchan.Uploads.SimpleS3Upload

  def gen_path(scope) do
    "#{scope}/#{UUID.uuid4(:hex)}"
  end

  # Usage in a Component:
  #
  # def presign_upload(entry, socket) do
  #   {:ok, meta} = Banchan.Uploads.presign_upload(
  #     Banchan.Uploads.gen_path("commission_uploads"),
  #     content_type: entry.content_type,
  #     max_file_size: socket.assigns.uploads.commission_uploads.max_file_size)
  #   {:ok, meta, socket}
  # end
  #
  def presign_upload(path, opts \\ []) do
    config = ExAws.Config.new(:s3)
    bucket = Application.fetch_env!(:ex_aws, :bucket)

    # TODO: Do I need to write to the db here? When do I write to db?
    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(
        config,
        bucket,
        [key: path] ++
          opts ++
          [
            expires_in: :timer.minutes(15)
          ]
      )

    meta = %{
      uploader: "S3",
      key: path,
      url: "http://#{bucket}.s3-#{config.region}.amazonaws.com",
      fields: fields
    }

    {:ok, meta}
  end
end
