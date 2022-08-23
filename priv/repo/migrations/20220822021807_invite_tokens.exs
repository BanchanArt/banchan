defmodule Banchan.Repo.Migrations.InviteTokens do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :available_invites, :integer, default: 0
    end

    create table(:artist_tokens) do
      add :token, :string
      add :generated_by_id, references(:users, on_delete: :nilify_all)
      add :used_by_id, references(:users, on_delete: :nilify_all)
      timestamps()
    end

    create table(:invite_requests) do
      add :email, :citext
      add :token_id, references(:artist_tokens, on_delete: :nilify_all)
      timestamps()
    end
  end
end
