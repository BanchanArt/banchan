defmodule Banchan.Uploads do
  alias Banchan.Uploads.SimpleS3Upload

  def gen_path(scope) do
    "#{scope}/#{UUID.uuid4(:hex)}"
  end

  def presign_upload(path, opts \\ []) do
    config = ExAws.Config.new(:s3)
    bucket = Application.fetch_env!(:ex_aws, :bucket)

    {:ok, fields} =
      SimpleS3Upload.sign_form_upload(
        config,
        bucket,
        [key: path] ++
          opts ++
          [
            max_file_size: 12_000_000,
            content_type: "application/octet-stream",
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
