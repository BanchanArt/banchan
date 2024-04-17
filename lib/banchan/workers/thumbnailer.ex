defmodule Banchan.Workers.Thumbnailer do
  @moduledoc """
  Worker responsible for generating thumbnails and  for uploaded media.
  """
  use Oban.Worker,
    queue: :media,
    unique: [period: 60],
    max_attempts: 5,
    tags: ["thumbnailer", "media"]

  import FFmpex, warn: false
  use FFmpex.Options

  alias Banchan.Accounts.User
  alias Banchan.Repo
  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  @impl Oban.Worker
  def perform(%_{
        id: job_id,
        args: %{
          "src" => src_id,
          "dest" => dest_id,
          "opts" => opts
        }
      }) do
    process(job_id, src_id, dest_id, opts)
  end

  def thumbnail(upload, opts \\ [])

  def thumbnail(%Upload{pending: true}, _) do
    # Only processed uploads can be thumbnailed.
    {:error, :pending}
  end

  def thumbnail(%Upload{} = upload, opts) do
    Task.async(fn ->
      if !Uploads.image?(upload) && !Uploads.video?(upload) do
        {:error, :unsupported_input}
      else
        :ok = Oban.Notifier.listen([:thumbnail_jobs])

        Ecto.Multi.new()
        |> Ecto.Multi.insert(
          :pending,
          Uploads.gen_pending(
            %User{id: upload.uploader_id},
            upload,
            "image/png",
            Keyword.get(opts, :name, "thumbnail.png")
          )
        )
        |> Ecto.Multi.run(:job, fn _repo, %{pending: pending} ->
          Oban.insert(
            __MODULE__.new(%{
              src: upload.id,
              dest: pending.id,
              opts: %{
                dimensions: Keyword.get(opts, :dimensions),
                upscale: Keyword.get(opts, :upscale)
              }
            })
          )
        end)
        |> Repo.transaction()
        |> case do
          {:ok, %{pending: pending, job: %{id: job_id}}} ->
            receive do
              {:notification, :thumbnail_jobs, %{"complete" => ^job_id, "result" => "ok"}} ->
                {:ok, Uploads.get_by_id!(pending.id)}

              {:notification, :thumbnail_jobs,
               %{"complete" => ^job_id, "result" => {"error", err}}} ->
                {:error, String.to_existing_atom(err)}
            after
              Keyword.get(opts, :timeout) || 300_000 ->
                {:error, :timeout}
            end

          {:error, _, error, _} ->
            {:error, error}
        end
      end
    end)
    |> Task.await(Keyword.get(opts, :timeout) || 300_000)
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp process(job_id, src_id, dest_id, opts) do
    Repo.transaction(fn ->
      src = Uploads.get_by_id!(src_id)
      dest = Uploads.get_by_id!(dest_id)

      tmp_src =
        Path.join([
          System.tmp_dir!(),
          src.key <> "#{System.unique_integer()}" <> Path.extname(src.name)
        ])

      File.mkdir_p!(Path.dirname(tmp_src))
      Uploads.write_data!(src, tmp_src)

      if Uploads.video?(src) do
        duration = FFprobe.duration(tmp_src)

        output_src = Path.join([System.tmp_dir!(), src.key <> ".png"])

        command =
          FFmpex.new_command()
          |> add_global_option(option_y())
          |> add_input_file(tmp_src)
          |> add_output_file(output_src)
          |> add_file_option(option_f("image2"))
          |> add_file_option(option_filter("scale=512:512"))
          |> add_file_option(option_ss(round(duration / 2)))
          |> add_file_option(option_vframes(1))

        {:ok, _} = execute(command)

        File.copy!(output_src, tmp_src)
      end

      tmp_dest =
        Path.join([
          System.tmp_dir!(),
          dest.key <> "#{System.unique_integer()}" <> Path.extname(dest.name)
        ])

      File.mkdir_p!(Path.dirname(tmp_dest))

      Image.thumbnail!(tmp_src, opts["dimensions"] || "256",
        resize:
          if opts["upscale"] do
            :both
          else
            :down
          end
      )
      |> Image.write!(tmp_dest, strip_metadata: true, minimize_file_size: true)

      Uploads.upload_file!(dest, tmp_dest)

      Uploads.update_upload!(dest, %{
        size: File.stat!(tmp_dest).size,
        pending: false
      })

      File.rm!(tmp_src)
      File.rm!(tmp_dest)

      {:ok, dest}
    end)
    |> case do
      {:ok, {:ok, _}} ->
        {:ok, dest_id}

      {:ok, {:error, error}} ->
        {:error, error}

      {:error, _} ->
        {:error, :processing_failed}
    end
    |> case do
      {:ok, dest_id} ->
        Oban.Notifier.notify(:thumbnail_jobs, %{complete: job_id, result: :ok})
        {:ok, dest_id}

      {:error, err} ->
        Oban.Notifier.notify(:thumbnail_jobs, %{complete: job_id, result: {:error, err}})
        {:error, err}
    end
  end
end
