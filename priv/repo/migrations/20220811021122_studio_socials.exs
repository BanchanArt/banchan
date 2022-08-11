defmodule Banchan.Repo.Migrations.StudioSocials do
  use Ecto.Migration

  def change do
    alter table(:studios) do
      add :website_url, :text
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
    end
  end
end
