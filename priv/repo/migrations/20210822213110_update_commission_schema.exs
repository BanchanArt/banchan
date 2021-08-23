defmodule Banchan.Repo.Migrations.UpdateCommissionSchema do
  use Ecto.Migration

  def change do
    alter table(:commissions) do
      remove :open
      add :status, :string
    end
  end
end
