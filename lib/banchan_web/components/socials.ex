defmodule BanchanWeb.Components.Socials do
  @moduledoc """
  Displays social media links.
  """
  use BanchanWeb, :component

  prop entity, :struct, required: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <div :if={!@entity.disable_info} class={"flex flex-row flex-wrap gap-4", @class}>
      <a
        :if={@entity.website_url}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={@entity.website_url}
      >
        <i class="fas fa-link" /><div class="font-medium text-sm hover:link">{@entity.website_url}</div>
      </a>
      <a
        :if={@entity.twitter_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://twitter.com/#{@entity.twitter_handle}"}
      >
        <i class="fa-brands fa-twitter" /><div class="font-medium text-sm hover:link">@{@entity.twitter_handle}</div>
      </a>
      <a
        :if={@entity.instagram_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://instagram.com/#{@entity.instagram_handle}"}
      >
        <i class="fa-brands fa-instagram" /><div class="font-medium text-sm hover:link">@{@entity.instagram_handle}</div>
      </a>
      <a
        :if={@entity.facebook_url}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={@entity.facebook_url}
      >
        <i class="fa-brands fa-facebook" />
      </a>
      <a
        :if={@entity.furaffinity_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.furaffinity.net/user/#{@entity.furaffinity_handle}"}
      >
        <img width="16" src={Routes.static_path(Endpoint, "/images/fa-favicon.svg")}><div class="font-medium text-sm hover:link">{@entity.furaffinity_handle}</div>
      </a>
      <div :if={@entity.discord_handle} class="flex flex-row flex-nowrap gap-1 items-center">
        <i class="fa-brands fa-discord" /><div class="font-medium text-sm hover:link">{@entity.discord_handle}</div>
      </div>
      <a
        :if={@entity.artstation_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://artstation.com/#{@entity.artstation_handle}"}
      >
        <i class="fa-brands fa-artstation" /><div class="font-medium text-sm hover:link">{@entity.artstation_handle}</div>
      </a>
      <a
        :if={@entity.deviantart_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.deviantart.com/#{@entity.deviantart_handle}"}
      >
        <i class="fa-brands fa-deviantart" /><div class="font-medium text-sm hover:link">{@entity.deviantart_handle}</div>
      </a>
      <a
        :if={@entity.tumblr_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.tumblr.com/blog/#{@entity.tumblr_handle}"}
      >
        <i class="fa-brands fa-tumblr" /><div class="font-medium text-sm hover:link">{@entity.tumblr_handle}</div>
      </a>
      <a
        :if={@entity.twitch_channel}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.twitch.tv/#{@entity.twitch_channel}"}
      >
        <i class="fa-brands fa-twitch" /><div class="font-medium text-sm hover:link">{@entity.twitch_channel}</div>
      </a>
      <a
        :if={@entity.pixiv_handle && @entity.pixiv_url}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={@entity.pixiv_url}
      >
        <img width="16" src={Routes.static_path(Endpoint, "/images/pixiv-favicon.svg")}><div class="font-medium text-sm hover:link">{@entity.pixiv_handle}</div>
      </a>
      <a
        :if={@entity.picarto_channel}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://picarto.tv/#{@entity.picarto_channel}"}
      >
        <img width="16" src={Routes.static_path(Endpoint, "/images/picarto-favicon.svg")}><div class="font-medium text-sm hover:link">{@entity.pixiv_handle}</div>
      </a>
      <a
        :if={@entity.tiktok_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://www.tiktok.com/@#{@entity.tiktok_handle}"}
      >
        <i class="fa-brands fa-tiktok" /><div class="font-medium text-sm hover:link">@{@entity.tiktok_handle}</div>
      </a>
      <a
        :if={@entity.artfight_handle}
        class="flex flex-row flex-nowrap gap-1 items-center"
        target="_blank"
        rel="noopener noreferrer"
        href={"https://artfight.net/~#{@entity.artfight_handle}"}
      >
        <img width="16" src={Routes.static_path(Endpoint, "/images/artfight-favicon.svg")}><div class="font-medium text-sm hover:link">~{@entity.artfight_handle}</div>
      </a>
    </div>
    """
  end
end
