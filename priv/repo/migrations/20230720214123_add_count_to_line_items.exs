defmodule Banchan.Repo.Migrations.AddCountToLineItems do
  use Ecto.Migration

  def change do
    alter table(:line_items) do
      add(:count, :integer, default: 1, null: false)
      add(:multiple, :boolean)
    end

    execute(
      fn ->
        repo().query!(
          """
          UPDATE line_items
          SET count = 1
          WHERE count IS NULL;
          """,
          [],
          log: false
        )
      end,
      fn -> :ok end
    )

    execute(
      fn ->
        repo().query!(
          """
          UPDATE line_items
          SET multiple = COALESCE(subq.multiple, false)
          FROM (SELECT opt.* FROM offering_options AS opt) AS subq
          WHERE line_items.multiple IS NULL AND subq.id = line_items.offering_option_id;
          """,
          [],
          log: false
        )
      end,
      fn -> :ok end
    )

    execute(
      fn ->
        repo().query!(
          """
          UPDATE line_items
          SET multiple = false
          WHERE multiple IS NULL;
          """,
          [],
          log: false
        )
      end,
      fn -> :ok end
    )

    alter table(:line_items) do
      modify(:multiple, :boolean,
        default: false,
        null: false,
        from: {:boolean, null: true, default: false}
      )
    end
  end
end
