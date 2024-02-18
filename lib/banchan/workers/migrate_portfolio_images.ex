defmodule Banchan.Workers.MigratePortfolioImages do
  @moduledoc """
  Takes care of migrating legacy PortfolioImages to the new Work-based system.
  """
  use Oban.Worker,
    queue: :migration,
    unique: [period: 60],
    tags: ["portfolio-images", "migration"]

  import Ecto.Query, warn: false

  alias Banchan.{Accounts, Accounts.User, Repo, Studios, Uploads, Works}

  def perform(%_{args: %{"portfolio_image_id" => portfolio_image_id, "actor_id" => actor_id}}) do
    actor = Accounts.get_user(actor_id)

    true = Accounts.admin?(actor)

    portfolio_image =
      from(
        pimg in Studios.PortfolioImage,
        where: pimg.id == ^portfolio_image_id,
        preload: [:studio, :upload]
      )
      |> Repo.one!()

    {:ok, _} =
      Works.new_work(
        actor,
        portfolio_image.studio,
        %{
          "title" => portfolio_image.upload.name || "Legacy Portfolio Image",
          "description" =>
            "This work was automatically imported from a legacy Studio portfolio image.",
          "tags" => ["banchan-legacy-import", "banchan-legacy-portfolio-image"]
        },
        uploads: [Uploads.clone_upload!(actor, portfolio_image.upload)]
      )

    Repo.delete!(portfolio_image)

    :ok
  end

  def queue_migration(%User{} = actor) do
    {:ok, _} =
      Repo.transaction(fn ->
        from(pimg in Studios.PortfolioImage, select: pimg.id)
        |> Repo.stream()
        |> Enum.each(fn pimg_id ->
          __MODULE__.new(%{
            "portfolio_image_id" => pimg_id,
            "actor_id" => actor.id
          })
          |> Oban.insert()
        end)
      end)

    :ok
  end
end
