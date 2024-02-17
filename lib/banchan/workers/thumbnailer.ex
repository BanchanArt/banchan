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
            "image/jpeg",
            Keyword.get(opts, :name, "thumbnail.jpg")
          )
        )
        |> Ecto.Multi.run(:job, fn _repo, %{pending: pending} ->
          Oban.insert(
            __MODULE__.new(%{
              src: upload.id,
              dest: pending.id,
              opts: %{
                target_size: Keyword.get(opts, :target_size),
                format: Keyword.get(opts, :format, "jpeg"),
                dimensions: Keyword.get(opts, :dimensions)
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

        output_src = Path.join([System.tmp_dir!(), src.key <> ".jpeg"])

        command =
          FFmpex.new_command()
          |> add_global_option(option_y())
          |> add_input_file(tmp_src)
          |> add_output_file(output_src)
          |> add_file_option(option_f("image2"))
          |> add_file_option(option_filter("scale=128:128"))
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

      # https://www.smashingmagazine.com/2015/06/efficient-image-resizing-with-imagemagick/
      Mogrify.open(tmp_src)
      |> Mogrify.custom("flatten")
      |> Mogrify.format(opts["format"])
      |> Mogrify.limit("area", "128MB")
      |> Mogrify.limit("disk", "1GB")
      |> Mogrify.custom("filter", "Triangle")
      |> Mogrify.custom("define", "filter:support=2")
      |> Mogrify.custom("unsharp", "0.25x0.25+8+0.065")
      |> Mogrify.custom("dither", "None")
      |> Mogrify.custom("posterize", "136")
      |> Mogrify.custom("quality", "82")
      |> Mogrify.custom("define", "jpeg:fancy-upsampling=off")
      |> Mogrify.custom("define", "png:compression-filter=5")
      |> Mogrify.custom("define", "png:compression-level=9")
      |> Mogrify.custom("define", "png:compression-strategy=1")
      |> Mogrify.custom("define", "png:exclude-chunk=all")
      |> Mogrify.custom("interlace", "none")
      |> Mogrify.custom("colorspace", "sRGB")
      |> Mogrify.custom("strip")
      |> then(fn mog ->
        if opts["target_size"] do
          mog
          |> Mogrify.custom("define", "#{opts["format"]}:extent=#{opts["target_size"]}")
        else
          mog
        end
      end)
      |> then(fn mog ->
        if opts["dimensions"] do
          mog
          |> Mogrify.gravity("Center")
          |> Mogrify.custom("thumbnail", opts["dimensions"])
          |> Mogrify.custom("extent", opts["dimensions"])
        else
          mog
        end
      end)
      |> Mogrify.save(path: tmp_dest)

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
