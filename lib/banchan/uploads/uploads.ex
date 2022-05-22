defmodule Banchan.Uploads do
  @moduledoc """
  The Uploads context.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Uploads.Upload

  @image_formats ~w(
    image/bmp image/gif image/png image/jpeg image/jpg
    image/x-icon image/jp2 image/psd image/vnd.adobe.photoshop
    image/tiff image/webp
  )

  @video_formats ~w(
    video/mpeg video/mp4 video/ogg video/webm video/x-msvideo video/x-ms-wmv
    video/quicktime
  )

  def image?(%Upload{type: type}) do
    type in @image_formats
  end

  def video?(%Upload{type: type}) do
    type in @video_formats
  end

  defp gen_key do
    UUID.uuid4(:hex)
  end

  defp local_upload_dir do
    Application.fetch_env!(:banchan, :upload_dir)
  end

  defp get_bucket do
    case Application.fetch_env!(:ex_aws, :bucket) do
      {:system, var} -> System.get_env(var) || "other"
      var when is_binary(var) -> var
      _ -> "other"
    end
  end

  def get_by_id!(id) do
    Repo.get!(Upload, id)
  end

  def get_upload!(bucket, key) do
    Repo.one!(from u in Upload, where: u.bucket == ^bucket and u.key == ^key)
  end

  def save_file!(%User{} = user, src, type, file_name, bucket \\ get_bucket()) do
    key = gen_key()
    size = File.stat!(src).size

    if Mix.env() == :prod || System.get_env("AWS_REGION") do
      src
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(bucket, key)
      |> ExAws.request!()
    else
      local = Path.join([local_upload_dir(), bucket, key])
      File.mkdir_p!(Path.dirname(local))
      File.cp!(src, local)
    end

    %Upload{
      uploader: user,
      name: file_name,
      key: key,
      bucket: bucket,
      type: type,
      size: size
    }
    |> Repo.insert!()
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
      File.stream!(local, [], 32_768)
    else
      ExAws.S3.download_file(upload.bucket, upload.key, :memory)
      |> ExAws.stream!()
    end
  end

  def delete_upload!(%Upload{} = upload) do
    Repo.delete!(upload)
  end
end
