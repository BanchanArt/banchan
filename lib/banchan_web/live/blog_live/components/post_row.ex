defmodule BanchanWeb.BlogLive.Components.PostRow do
  @moduledoc """
  Component for displaying blog post rows.
  """
  use BanchanWeb, :component

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias BanchanWeb.Components.{Avatar, Icon, Tag, UserHandle}

  prop post, :struct, required: true

  def render(assigns) do
    post_url =
      ~p"/blog/#{assigns.post.date.year}/#{assigns.post.date.month |> Integer.to_string() |> String.pad_leading(2, "0")}/#{assigns.post.date.day |> Integer.to_string() |> String.pad_leading(2, "0")}/#{assigns.post.id}"

    ~F"""
    <li class="relative flex items-center justify-between gap-x-6 p-4 cursor-pointer rounded-box transition-all hover:bg-base-200">
      <div class="min-w-0">
        <LivePatch to={post_url}>
          <span class="absolute inset-x-0 -top-px bottom-0" />
          <p class="text-md font-semibold leading-6">{@post.title}</p>
          <h4 class="text-sm opacity-80">{@post.description}</h4>
        </LivePatch>
        <div class="mt-1 flex flex-wrap items-center gap-x-2 text-xs leading-5">
          <p class="whitespace-nowrap">
            published
            <time datetime={@post.date |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>
              {@post.date |> Timex.to_datetime() |> Timex.format!("{ISOdate}")}
            </time>
          </p>
          <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 fill-current">
            <circle cx="1" cy="1" r="1" />
          </svg>
          By
          {#if @post.user}
            <LiveRedirect to={~p"/denizens/#{@post.user.handle}"}>
              <div class="self-center inline">
                <Avatar link={false} user={@post.user} class="w-2.5" />
              </div>
              <div class="inline">
                <UserHandle link={false} user={@post.user} />
              </div>
            </LiveRedirect>
          {#else}
            <span class="fonts-semibold">
              {@post.author}
            </span>
          {/if}
        </div>
        <ul class="pt-2 flex flex-row gap-2">
          {#for tag <- @post.tags}
            <li class="z-10">
              <LivePatch to={~p"/blog/tag/#{tag}"}>
                <Tag tag={tag} link={false} />
              </LivePatch>
            </li>
          {/for}
        </ul>
      </div>
      <div class="shrink-0">
        <Icon name="chevron-right" class="h-5 w-5 opacity-75" />
      </div>
    </li>
    """
  end
end
