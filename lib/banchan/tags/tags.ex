defmodule Banchan.Tags do
  @moduledoc """
  Context module for Tag-related operations.
  """
  import Ecto.Query, warn: false

  alias Banchan.Repo
  alias Banchan.Tags.Tag

  def list_tags(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 20)
    from(tag in Tag,
      select: tag
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end
end
