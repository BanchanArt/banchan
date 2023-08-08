defmodule Banchan.Utils do
  @moduledoc """
  Collection of miscellaneous utilities that don't quite fit anywhere else.
  """

  def moneyfy(amount, currency) when is_binary(currency) do
    currency = currency |> String.upcase() |> String.to_existing_atom()
    moneyfy(amount, currency)
  rescue
    ArgumentError ->
      amount
  end

  def moneyfy(amount, currency) when is_atom(currency) do
    case Money.parse(amount, currency) do
      {:ok, money} ->
        money

      :error ->
        # NB(zkat): the assumption here is that the value will be validated by
        # Ecto changeset stuff.
        amount
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def has_socials?(entity) do
    !(is_nil(entity.website_url) &&
        is_nil(entity.twitter_handle) &&
        is_nil(entity.instagram_handle) &&
        is_nil(entity.facebook_url) &&
        is_nil(entity.furaffinity_handle) &&
        is_nil(entity.discord_handle) &&
        is_nil(entity.artstation_handle) &&
        is_nil(entity.deviantart_handle) &&
        is_nil(entity.tumblr_handle) &&
        is_nil(entity.mastodon_handle) &&
        is_nil(entity.twitch_channel) &&
        is_nil(entity.picarto_channel) &&
        is_nil(entity.pixiv_url) &&
        is_nil(entity.pixiv_handle) &&
        is_nil(entity.tiktok_handle) &&
        is_nil(entity.artfight_handle))
  end
end
