defmodule Banchan.Validators do
  @moduledoc """
  Shared validators.
  """
  import Ecto.Changeset

  def validate_handle(changeset, field) do
    changeset
    |> validate_required(field)
    |> validate_format(field, ~r/^[a-zA-Z0-9_-]+$/,
      message: "only letters, numbers, and underscores are allowed"
    )
    |> validate_length(field, min: 3, max: 24)
    |> unsafe_validate_unique(field, Banchan.Repo)
    |> unique_constraint(field)
  end

  def validate_email(changeset, field) do
    changeset
    |> validate_format(field, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(field, max: 160)
  end

  def validate_unique_email(changeset, field) do
    changeset
    |> validate_email(field)
    |> unsafe_validate_unique(field, Banchan.Repo)
    |> unique_constraint(field)
  end

  def validate_money(changeset, field, max \\ nil) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 and (is_nil(max) or amount <= max.amount) ->
        []

      _, %Money{} when not is_nil(max) ->
        [
          {field,
           "Must be an amount between #{Money.new(0, max.currency) |> Money.to_string()} and #{Money.to_string(max)}."}
        ]

      _, "" ->
        []

      _, nil ->
        []

      _, _ ->
        [{field, "Must be a positive money amount."}]
    end)
  end

  def validate_markdown(changeset, field) do
    validate_change(changeset, field, fn _, data ->
      # NB(@zkat): We don't care about whitespace changes.
      if String.replace(data, ~r/\s+/, "") ==
           String.replace(HtmlSanitizeEx.markdown_html(data), ~r/\s+/, "") do
        []
      else
        [{field, "Disallowed HTML detected. Some tags, like <script>, are not allowed."}]
      end
    end)
  end

  # :tags is hardcoded because the trigger expects the column to be called :tags
  def validate_tags(changeset) do
    changeset
    |> validate_change(:tags, fn field, tags ->
      if tags |> Enum.map(&String.downcase/1) ==
           tags |> Enum.map(&String.downcase/1) |> Enum.uniq() do
        []
      else
        [{field, "cannot have duplicate tags."}]
      end
    end)
    |> validate_change(:tags, fn field, tags ->
      if Enum.count(tags) > 10 do
        [{field, "cannot have more than 10 tags."}]
      else
        []
      end
    end)
    |> validate_change(:tags, fn field, tags ->
      if Enum.all?(tags, fn tag ->
           String.match?(tag, ~r/^.{0,100}$/)
         end) do
        []
      else
        [{field, "Tags can only be up to 100 characters long."}]
      end
    end)
  end

  def cast_socials(data, attrs) do
    data
    |> cast(attrs, [
      :website_url,
      :twitter_handle,
      :instagram_handle,
      :facebook_url,
      :furaffinity_handle,
      :discord_handle,
      :artstation_handle,
      :deviantart_handle,
      :tumblr_handle,
      :mastodon_handle,
      :twitch_channel,
      :picarto_channel,
      :pixiv_url,
      :pixiv_handle,
      :tiktok_handle,
      :artfight_handle
    ])
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def validate_socials(changeset) do
    changeset
    |> validate_format(:website_url, ~r/^https?:\/\/[^\s]+$/, message: "must be a valid URL")
    |> validate_format(:twitter_handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Twitter handle, without the @ sign."
    )
    |> validate_format(:instagram_handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Instagram handle, without the @ sign."
    )
    |> validate_format(:facebook_url, ~r/^https:\/\/(www\.)?facebook\.com\/.+$/,
      message: "must be a valid Facebook URL."
    )
    |> validate_format(:furaffinity_handle, ~r/^[a-zA-Z0-9_-]+$/,
      message: "must be a valid Furaffinity handle."
    )
    |> validate_format(:discord_handle, ~r/^[a-zA-Z0-9_-]+#\d{4}$/,
      message: "must be a valid Discord handle, including the number (myname#1234)."
    )
    |> validate_format(:artstation_handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Artstation handle."
    )
    |> validate_format(:deviantart_handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Deviantart handle."
    )
    |> validate_format(:tumblr_handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Tumblr handle."
    )
    |> validate_format(:mastodon_handle, ~r/^[a-zA-Z0-9_-]+@.+$/,
      message:
        "must be a valid Mastodon handle, without the preceding @. For example: `foo@mastodon.social`."
    )
    |> validate_format(:twitch_channel, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Twitch channel name."
    )
    |> validate_format(:picarto_channel, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Picarto channel name."
    )
    |> validate_format(:pixiv_url, ~r/^https:\/\/(www\.)?pixiv\.net\/[a-zA-Z]{2}\/users\/\d+$/,
      message: "must be a valid Pixiv URL, like `https://pixiv.net/en/users/12345`."
    )
    |> validate_change(:pixiv_url, fn field, _ ->
      if Ecto.Changeset.fetch_field(changeset, :pixiv_handle) == :error do
        [{field, "Must provide both a pixiv handle and a pixiv url, or neither."}]
      else
        []
      end
    end)
    |> validate_change(:pixiv_handle, fn field, _ ->
      if Ecto.Changeset.fetch_field(changeset, :pixiv_url) == :error do
        [{field, "Must provide both a pixiv handle and a pixiv url, or neither."}]
      else
        []
      end
    end)
    |> validate_format(:pixiv_handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid Pixiv handle."
    )
    |> validate_format(:tiktok_handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "must be a valid TikTok handle, without the @ sign."
    )
    |> validate_format(:artfight_handle, ~r/^[a-zA-Z0-9_-]+$/,
      message: "must be a valid Artfight handle, without the ~ sign."
    )
  end
end
