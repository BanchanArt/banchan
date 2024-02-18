defmodule Banchan.Workers.MigrateGalleryImages do
  @moduledoc """
  Takes care of migrating legacy GalleryImages to the new Work-based system.
  """
  use Oban.Worker,
    queue: :migration,
    unique: [period: 60],
    tags: ["offering-gallery-images", "migration"]

  import Ecto.Query, warn: false

  alias Banchan.{Accounts, Accounts.User, Offerings, Repo, Uploads, Works}

  def perform(%_{args: %{"gallery_image_id" => gallery_image_id, "actor_id" => actor_id}}) do
    actor = Accounts.get_user(actor_id)

    true = Accounts.admin?(actor)

    gimg =
      from(
        gimg in Offerings.GalleryImage,
        where: gimg.id == ^gallery_image_id,
        preload: [:upload, offering: [:studio]]
      )
      |> Repo.one!()

    {:ok, _} =
      Works.new_work(
        actor,
        gimg.offering.studio,
        %{
          "title" => gimg.upload.name || "Legacy Offering Gallery Image",
          "description" =>
            "This work was automatically imported from a legacy Offering gallery image.",
          "tags" => ["banchan-legacy-import", "banchan-legacy-gallery-image"]
        },
        uploads: [Uploads.clone_upload!(actor, gimg.upload)],
        offering: gimg.offering
      )

    Repo.delete!(gimg)

    :ok
  end

  def queue_migration(%User{} = actor) do
    {:ok, _} =
      Repo.transaction(fn ->
        from(gimg in Offerings.GalleryImage, select: gimg.id)
        |> Repo.stream()
        |> Enum.each(fn gimg_id ->
          __MODULE__.new(%{
            "gallery_image_id" => gimg_id,
            "actor_id" => actor.id
          })
          |> Oban.insert()
        end)
      end)

    :ok
  end
end
