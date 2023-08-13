defmodule Banchan.Blog do
  @moduledoc """
  Context module for the Banchan.Art blog.
  """
  alias Banchan.Blog.Post

  use NimblePublisher,
    build: Post,
    from: Application.app_dir(:banchan, "priv/posts/**/*.md"),
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  alias Banchan.Accounts

  # The @posts variable is first defined by NimblePublisher.
  # Let's further modify it by sorting all posts by descending date.
  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  # Let's also get all tags
  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  # And finally export them
  def all_posts, do: @posts |> Enum.map(&%{&1 | user: Accounts.get_user_by_handle(&1.author)})
  def all_tags, do: @tags

  def published_posts, do: Enum.filter(all_posts(), & &1.published)

  defmodule NotFoundError, do: defexception([:message, plug_status: 404])

  def get_post!(year, month, day, id) do
    date =
      Date.from_iso8601!(
        "#{year}-#{month |> String.pad_leading(2, "0")}-#{day |> String.pad_leading(2, "0")}"
      )

    Enum.find(published_posts(), &(&1.id == id && &1.date == date)) ||
      raise NotFoundError, "post with id=#{id} on #{date} not found"
  end

  def get_posts_by_tag!(tag) do
    case Enum.filter(published_posts(), &(tag in &1.tags)) do
      [] -> raise NotFoundError, "posts with tag=#{tag} not found"
      posts -> posts
    end
  end
end
