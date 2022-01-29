defmodule Banchan.Repo.Migrations.ExtraCommissionFields do
  use Ecto.Migration

  def change do
    alter table(:commissions) do
      add :public_id, :string, null: false
    end

    create unique_index(:commissions, [:public_id, :studio_id])
  end
end
