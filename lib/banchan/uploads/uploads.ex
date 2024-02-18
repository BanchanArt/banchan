defmodule Banchan.Uploads do
  @moduledoc """
  The Uploads context.
  """
  import Ecto.Query, warn: false

  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Uploads.Upload

  # Supported image formats for prebuilt libvips binaries:
  # https://github.com/akash-akya/vix?tab=readme-ov-file#pre-compiled-nif-and-libvips
  @image_formats ~w(
    image/gif image/png image/jpeg image/jpg
    image/tiff image/webp image/svg+xml
  )

  @image_format_extensions ~w(
    .gif .png .jpeg .jpg .tiff .webp .svg
  )

  @video_formats ~w(
    video/mpeg video/mp4 video/ogg video/webm video/x-msvideo video/x-ms-wmv
    video/quicktime
  )

  ## Getting

  @doc """
  Returns a list of extensions currently supported image formats.
  """
  def supported_image_format_extensions do
    @image_format_extensions
  end

  @doc """
  Returns true if an upload (or a given string type) is an image.
  """
  def image?(%Upload{type: type}) do
    image?(type)
  end

  def image?(type) when is_binary(type) do
    type in @image_formats
  end

  @doc """
  Returns true if an upload (or a given string type) is a video.
  """
  def video?(%Upload{type: type}) do
    video?(type)
  end

  def video?(type) when is_binary(type) do
    type in @video_formats
  end

  @doc """
  Returns true if an upload (or a given string type) is a visual media type.
  """
  def media?(type), do: image?(type) || video?(type)

  @doc """
  Maximum upload size.
  """
  def max_upload_size do
    Application.fetch_env!(:banchan, :max_attachment_size)
  end

  @doc """
  Convert an error atom to a human-readable error message.
  """
  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unsupported file type"

  @doc """
  Fetches an upload by its (binary) id, throwing if the Upload does not exist.
  """
  def get_by_id!(id) do
    Repo.get!(Upload, id)
  end

  @doc """
  Fetches an upload by its (binary) id, returning nil if the Upload does not exist.
  """
  def get_by_id(id) do
    Repo.get(Upload, id)
  end

  @doc """
  Gets all Upload data in-memory. Raises if the upload is pending or the data
  is not available.

  ## Examples
      iex> get_data!(upload)
      <<123, 456, ...>>

  """
  def get_data!(upload) do
    local = Path.join([local_upload_dir(), upload.bucket, upload.key])

    if upload.pending do
      raise "Tried to get data for a pending upload"
    end

    if File.exists?(local) do
      File.read!(local)
    else
      ExAws.S3.get_object(upload.bucket, upload.key)
      |> ExAws.request!()
      |> Map.get(:body)
    end
  end

  @doc """
  Get Upload data in Stream form. Raises if the upload is pending or the data
  is not available.

  ## Examples
      iex> stream_data!(upload)
      #Stream<[...]>

  """
  def stream_data!(upload) do
    local = Path.join([local_upload_dir(), upload.bucket, upload.key])

    if upload.pending do
      raise "Tried to get data for a pending upload"
    end

    if File.exists?(local) do
      File.stream!(local, [], 32_768)
    else
      ExAws.S3.download_file(upload.bucket, upload.key, :memory)
      |> ExAws.stream!()
    end
  end

  @doc """
  Write Upload data to disk. Raises if the upload is pending or the data is
  not available.

  ## Examples
      iex> write_data!(upload, "/tmp/file.txt")
      :ok
  """
  def write_data!(%Upload{} = upload, dest) do
    local = Path.join([local_upload_dir(), upload.bucket, upload.key])

    if upload.pending do
      raise "Tried to get data for a pending upload"
    end

    if File.exists?(local) do
      File.cp!(local, dest)
    else
      ExAws.S3.download_file(upload.bucket, upload.key, dest)
      |> ExAws.request!()
    end
  end

  ## Creation

  @doc """
  Saves a file as an Upload, putting it in the appropriate Upload storage.
  """
  def save_file!(%User{} = user, src, type, file_name) do
    bucket = get_bucket() || "default-uploads-bucket"
    key = gen_key()
    size = File.stat!(src).size

    upload = %Upload{
      uploader_id: user.id,
      name: file_name,
      key: key,
      bucket: bucket,
      type: type,
      size: size,
      pending: false
    }

    upload_file!(upload, src)

    upload
    |> Repo.insert!()
  end

  @doc """
  Uploads data from `src` to Upload's storage. Does not otherwise modify the Upload.
  """
  def upload_file!(%Upload{} = upload, src) do
    if Application.fetch_env!(:banchan, :env) == :prod ||
         !is_nil(Application.get_env(:ex_aws, :region)) do
      src
      |> ExAws.S3.Upload.stream_file()
      |> ExAws.S3.upload(upload.bucket, upload.key)
      |> ExAws.request!()
    else
      local = Path.join([local_upload_dir(), upload.bucket, upload.key])
      File.mkdir_p!(Path.dirname(local))
      File.cp!(src, local)
    end

    :ok
  end

  @doc """
  Creates a pending Upload--that is, an Upload whose metadata is present, and
  which shows up in many queries, but whose data is not yet available.

  This function does not insert the Upload itself, only returns it.
  """
  def gen_pending(%User{} = user, %Upload{} = original, type, file_name) do
    bucket = get_bucket() || "default-uploads-bucket"
    key = gen_key()

    %Upload{
      uploader_id: user.id,
      original_id: original.id,
      name: file_name,
      key: key,
      bucket: bucket,
      type: type,
      pending: true
    }
  end

  ## Editing

  @doc """
  Updates Upload fields. Does not affect stored Upload data.
  """
  def update_upload!(%Upload{} = upload, attrs) do
    upload
    |> Upload.update_changeset(attrs)
    |> Repo.update!(return: true)
  end

  ## Deletion

  @doc """
  Deletes an upload and its stored data.
  """
  def delete_upload(%Upload{} = upload) do
    if Application.fetch_env!(:banchan, :env) == :prod ||
         !is_nil(Application.get_env(:ex_aws, :region)) do
      ExAws.S3.delete_object(upload.bucket, upload.key) |> ExAws.request()
    else
      local = Path.join([local_upload_dir(), upload.bucket, upload.key])
      File.rm(local)
    end
    |> case do
      :ok -> Repo.delete(upload)
      {:ok, _} -> Repo.delete(upload)
      {:error, error} -> {:error, error}
    end
  end

  ## Misc internal utilities

  defp gen_key do
    UUID.uuid4(:hex)
  end

  defp local_upload_dir do
    Application.fetch_env!(:banchan, :upload_dir)
  end

  defp get_bucket do
    case Application.fetch_env(:ex_aws, :bucket) do
      {:ok, {:system, var}} -> System.get_env(var)
      {:ok, var} when is_binary(var) -> var
      :error -> nil
    end
  end
end
