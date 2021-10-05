defmodule Banchan.Repo.Migrations.ChangeSlugToHandle do
  use Ecto.Migration

  def change do
    rename table(:studios), :slug, to: :handle
  end
end
