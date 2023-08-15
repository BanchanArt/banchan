defmodule BanchanWeb.BlogLive do
  use BanchanWeb, :live_view

  alias Banchan.Blog

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias BanchanWeb.BlogLive.Components.PostRow
  alias BanchanWeb.Components.{Avatar, Layout, Tag, UserHandle}

  def handle_params(params, _uri, socket) do
    case params do
      %{"tag" => tag} ->
        {:noreply,
         assign(
           socket,
           post: nil,
           tag: tag,
           posts: Blog.get_posts_by_tag!(tag),
           page_title: "Blog",
           page_description: "Blog posts by tag: #{tag}"
         )}

      %{"year" => year, "month" => month, "day" => day, "id" => id} ->
        post = Blog.get_post!(year, month, day, id)

        {:noreply,
         assign(
           socket,
           tag: socket.assigns[:tag],
           post: post,
           page_title: "Blog Post: #{post.title}",
           page_description: post.description
         )}

      _ ->
        {:noreply,
         assign(
           socket,
           post: nil,
           tag: nil,
           posts: Blog.published_posts(),
           page_title: "Blog",
           page_description: "Banchan.Art blog posts"
         )}
    end
  end

  def render(assigns) do
    ~F"""
    <Layout flashes={@flash}>
      <LivePatch to={if @tag && @post do
        ~p"/blog/tag/#{@tag}"
      else
        ~p"/blog"
      end}>
        <div class="text-3xl font-bold">Banchan.Art Blog</div>
      </LivePatch>
      <div class="divider" />
      {#if @post}
        <div class="flex flex-col">
          <h2 class="text-xl font-semibold">{@post.title}</h2>
          <h4 class="text-sm opacity-80">{@post.description}</h4>
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
              <LiveRedirect to={~p"/people/#{@post.user.handle}"}>
                <div class="self-center inline">
                  <Avatar link={false} user={@post.user} class="w-2.5" />
                </div>
                <div class="inline">
                  <UserHandle link={false} user={@post.user} />
                </div>
              </LiveRedirect>
            {#else}
              <span class="font-semibold">
                {@post.author}
              </span>
            {/if}
          </div>
          <ul class="pt-2 flex flex-row gap-2 pb-4">
            {#for tag <- @post.tags}
              <li class="z-10">
                <LivePatch to={~p"/blog/tag/#{tag}"}>
                  <Tag tag={tag} link={false} />
                </LivePatch>
              </li>
            {/for}
          </ul>
          <div class="prose">
            {raw(@post.body)}
          </div>
        </div>
      {#else}
        {#if @tag}
          <h2 class="text-2xl font-semibold flex flex-row gap-2 items-center">
            <span>Posts tagged with</span>
            <Tag tag={@tag} link={false} />
            <LivePatch to={~p"/blog"} class="text-sm link">(reset)</LivePatch>
          </h2>
        {/if}
        <ul role="list" class="divide-y divide-base-200">
          {#for post <- @posts}
            <PostRow post={post} />
          {/for}
        </ul>
      {/if}
    </Layout>
    """
  end
end
