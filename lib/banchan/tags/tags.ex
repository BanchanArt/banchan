defmodule Banchan.Tags do
  @moduledoc """
  Context module for Tag-related operations.
  """
  import Ecto.Query, warn: false

  alias Banchan.Repo
  alias Banchan.Tags.Tag

  def list_tags(like, opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 20)

    like =
      if like == "" do
        like
      else
        like <> "%"
      end

    from(tag in Tag,
      select: tag,
      where: ilike(tag.tag, ^like)
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end
end
