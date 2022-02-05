defmodule Banchan.Uploads do
  @moduledoc """
  The Uploads context.
  """

  import Ecto.Query, warn: false
  alias Banchan.Repo
  alias Banchan.Uploads.Upload

  @doc """
  Generates a unique path for an upload.
  """
  def gen_path do
    UUID.uuid4(:hex)
  end

  defp local_upload_dir do
    Application.fetch_env!(:banchan, :upload_dir)
  end

  @doc """
  Gets all Upload data in-memory.

  ## Examples
      iex> get_data!(upload)
      <<123, 456, ...>>

  """
  def get_data!(upload) do
    local = Path.join([local_upload_dir(), upload.bucket, upload.key])

    if File.exists?(local) do
      File.read!(local)
    else
      ExAws.S3.get_object(upload.bucket, upload.key)
      |> ExAws.request!()
      |> Map.get(:body)
    end
  end

  @doc """
  Get Upload data in Stream form.

  ## Examples
      iex> stream_data!(upload)
      #Stream<[...]>

  """
  def stream_data!(upload) do
    local = Path.join([local_upload_dir(), upload.bucket, upload.key])

    if File.exists?(local) do
      File.stream!(local)
    else
      ExAws.S3.download_file(upload.bucket, upload.key, :memory)
      |> ExAws.stream!()
    end
  end

  @doc """
  Gets the content length of an Upload.
  """
  def get_size!(upload) do
    local = Path.join([local_upload_dir(), upload.bucket, upload.key])

    if File.exists?(local) do
      File.stat!(local).size
    else
    ExAws.S3.head_object(upload.bucket, upload.key)
    |> ExAws.request!()
    |> Map.get(:headers)
    |> List.keyfind("Content-Length", 0)
    |> elem(1)
    |> Integer.parse()
    |> elem(0)
    end
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
