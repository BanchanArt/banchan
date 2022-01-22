defmodule Banchan.Uploads do
  @moduledoc """
  The Uploads context.
  """

  import Ecto.Query, warn: false
  alias Banchan.Repo
  alias Banchan.Uploads.SimpleS3Upload
  alias Banchan.Uploads.Upload

  @doc """
  Generates a unique path for an upload.
  """
  def gen_path() do
    UUID.uuid4(:hex)
  end

  @doc """
  Usage in a Component:

  def presign_upload(entry, socket) do
    {:ok, meta} = Banchan.Uploads.presign_upload(
      Banchan.Uploads.gen_path(),
      content_type: entry.content_type,
      max_file_size: socket.assigns.uploads.commission_uploads.max_file_size)
    {:ok, meta, socket}
  end
  """
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

  @doc """
  Returns a list of uploads.

  ## Examples

      iex> list_uploads()
      [%Upload{}, ...]

  """
  def list_uploads() do
    Repo.all(Upload)
  end

  @doc """
  Gets a single upload.

  ## Examples

      iex> get_upload!(123)
      %Upload{}

      iex> get_upload!(321)
      ** (Ecto.NoResultsError)

  """
  def get_upload!(id) do
    Repo.get!(Upload, id)
  end

  @doc """
  Gets all Upload data in-memory.

  ## Examples
      iex> get_data!(upload)
      <<123, 456, ...>>

  """
  def get_data!(upload) do
    ExAws.S3.get_object(upload.bucket, upload.key)
    |> ExAws.request!()
    |> Map.get(:body)
  end

  @doc """
  Get Upload data in Stream form.

  ## Examples
      iex> stream_data!(upload)
      #Stream<[...]>

  """
  def stream_data!(upload) do
    ExAws.S3.download_file(upload.bucket, upload.key, :memory)
    |> ExAws.stream!()
  end

  @doc """
  Gets the content length of an Upload.
  """
  def get_size!(upload) do
    ExAws.S3.head_object(upload.bucket, upload.key)
    |> ExAws.request!()
    |> Map.get(:headers)
    |> List.keyfind("Content-Length", 0)
    |> elem(1)
    |> Integer.parse()
    |> elem(0)
  end

  @doc """
  Creates an Upload.

  ## Examples

      iex> create_upload(%{bucket: "foo", key: "bar", content_type: "text/plain"})
      {:ok, %Upload{}}

  """
  def create_upload(attrs \\ %{}) do
    %Upload{}
    |> Upload.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes an Upload. This will also delete it from S3 unless `delete_from_s3` is `false`.

  ## Examples

      iex> delete_upload(upload)
      {:ok, %Upload{}}

      iex> delete_upload(upload)
      {:error, %Ecto.Changeset{}}

  """
  def delete_upload(%Upload{bucket: bucket, key: key} = upload, delete_from_s3 \\ true) do
    if delete_from_s3 do
      ExAws.S3.delete_object(bucket, key) |> ExAws.request!()
    end

    Repo.delete(upload)
  end
end
