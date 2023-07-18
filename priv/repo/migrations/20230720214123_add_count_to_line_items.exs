defmodule Banchan.Repo.Migrations.AddCountToLineItems do
  use Ecto.Migration

  def change do
    alter table(:line_items) do
      add(:count, :integer, default: 1)
    end

    execute(fn ->
      repo().query!(
        """
        UPDATE line_items
        SET count = 1
        WHERE count IS NULL;
        """,
        [],
        log: false
      )
    end, fn -> :ok end)

    alter table(:line_items) do
      modify(:count, :integer, default: 1, null: false, from: {:integer, null: true, default: 1})
    end
  end
end
