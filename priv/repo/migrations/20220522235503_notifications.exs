defmodule Banchan.Repo.Migrations.Notifications do
  use Ecto.Migration

  def change do
    create table(:commission_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :commission_id, references(:commissions, on_delete: :delete_all)
      add :silenced, :boolean, default: false

      timestamps()
    end

    create unique_index(:commission_subscriptions, [:user_id, :commission_id])
    create index(:commission_subscriptions, [:commission_id])

    create table(:studio_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :studio_id, references(:studios, on_delete: :delete_all)
      add :silenced, :boolean, default: false

      timestamps()
    end

    create unique_index(:studio_subscriptions, [:user_id, :studio_id])
    create index(:studio_subscriptions, [:studio_id])

    create table(:offering_subscriptions) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :offering_id, references(:offerings, on_delete: :delete_all)
      add :silenced, :boolean, default: false

      timestamps()
    end

    create unique_index(:offering_subscriptions, [:user_id, :offering_id])
    create index(:offering_subscriptions, [:offering_id])

    create table(:user_notifications) do
      add :ref, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :title, :text, null: false
      add :short_body, :text
      add :text_body, :text
      add :html_body, :text
      add :url, :string
      add :read, :boolean, default: false

      timestamps()
    end

    create index(:user_notifications, [:user_id])
    create unique_index(:user_notifications, [:ref, :user_id])

    create table(:user_notification_settings) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :commission_email, :boolean, default: true
      add :commission_web, :boolean, default: true

      timestamps()
    end

    create unique_index(:user_notification_settings, [:user_id])
  end
end
