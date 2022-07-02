defmodule Banchan.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    create table(:uploads, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :bucket, :string, null: false
      add :key, :string, null: false
      add :type, :string
      add :size, :integer, null: false
      add :width, :integer
      add :height, :integer

      timestamps()
    end

    create unique_index(:uploads, [:bucket, :key])

    create table(:users) do
      # Identity/Auth
      add :handle, :citext, null: false
      add :email, :citext
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :totp_secret, :binary
      add :totp_activated, :boolean

      # OAuth
      add :twitter_uid, :text
      add :google_uid, :text
      add :discord_uid, :text

      # Perms and Moderation
      add :roles, {:array, :string}, default: [], null: false
      add :moderation_notes, :text

      # Profile
      add :name, :string
      add :bio, :string
      # Array fields are the best/fastest approach in most cases.
      # http://www.databasesoup.com/2015/01/tag-all-things.html
      add :tags, {:array, :citext}, default: [], null: false
      add :header_img_id, references(:uploads, on_delete: :nilify_all, type: :uuid)
      add :pfp_img_id, references(:uploads, on_delete: :nilify_all, type: :uuid)
      add :pfp_thumb_id, references(:uploads, on_delete: :nilify_all, type: :uuid)

      # Social Media
      add :twitter_handle, :text
      add :instagram_handle, :text
      add :facebook_url, :text
      add :furaffinity_handle, :text
      add :discord_handle, :text
      add :artstation_handle, :text
      add :deviantart_handle, :text
      add :tumblr_handle, :text
      add :mastodon_handle, :text
      add :twitch_channel, :text
      add :picarto_channel, :text
      add :pixiv_url, :text
      add :pixiv_handle, :text
      add :tiktok_handle, :text
      add :artfight_handle, :text

      timestamps()
    end

    execute(
      fn ->
        repo().query!(
          """
          ALTER TABLE users ADD COLUMN search_vector tsvector
            GENERATED ALWAYS AS (
              setweight(to_tsvector('banchan_fts', handle), 'A') ||
              setweight(to_tsvector('banchan_fts', coalesce(name, '')), 'B')
            ) STORED;
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          CREATE INDEX users_search_idx ON users USING GIN (search_vector);
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          CREATE INDEX users_tags ON users USING GIN (tags);
          """,
          [],
          log: :info
        )

        repo().query!("""
        CREATE TRIGGER users_tags_count_update
        AFTER UPDATE OR INSERT OR DELETE ON users
        FOR EACH ROW
        EXECUTE PROCEDURE public.trigger_update_tags_count();
        """)
      end,
      fn ->
        repo().query!(
          """
          DROP INDEX users_search_idx;
          """,
          [],
          log: :info
        )

        repo().query!(
          """
          DROP INDEX users_tags;
          """,
          [],
          log: :info
        )

        repo().query!("""
        DROP TRIGGER users_tag_count_update;
        """)
      end
    )

    create unique_index(:users, [:email])
    create unique_index(:users, [:handle])

    create index(:users, [:header_img_id])
    create index(:users, [:pfp_img_id])
    create index(:users, [:pfp_thumb_id])

    alter table(:uploads) do
      add :uploader_id, references(:users, on_delete: :nilify_all)
    end

    create index(:uploads, [:uploader_id])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    create table(:disable_history) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :disabled_by_id, references(:users, on_delete: :delete_all)
      add :disabled_at, :naive_datetime
      add :disabled_until, :naive_datetime
      add :disabled_reason, :text
      add :lifted_reason, :text
      add :lifted_at, :naive_datetime
    end

    create index(:disable_history, [:user_id])
  end
end
