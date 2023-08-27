defmodule Banchan.Repo.Migrations.AddOauthOnlyColumn do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:oauth_only, :boolean, default: false)
    end

    execute(
      fn ->
        repo().query!(
          """
          UPDATE users
          SET oauth_only = TRUE
          WHERE email IS NULL;
          """,
          [],
          log: false
        )
      end,
      fn -> :ok end
    )
  end
end
