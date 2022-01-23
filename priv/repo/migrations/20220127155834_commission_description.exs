defmodule Banchan.Repo.Migrations.CommissionDescription do
  use Ecto.Migration

  def change do
    alter table(:commissions) do
      add :description, :text
    end
  end
end
