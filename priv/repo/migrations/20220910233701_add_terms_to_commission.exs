defmodule Banchan.Repo.Migrations.AddTermsToCommission do
  use Ecto.Migration

  def change do
    alter table(:commissions) do
      add :terms, :text
    end
  end
end
