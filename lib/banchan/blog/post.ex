defmodule Banchan.Blog.Post do
  @moduledoc """
  Struct for blog posts.
  """

  @enforce_keys [:id, :author, :user, :title, :body, :description, :tags, :date, :published]
  defstruct [:id, :author, :user, :title, :body, :description, :tags, :date, :published]

  def build(filename, attrs, body) do
    [year, month_day_id] = filename |> Path.rootname() |> Path.split() |> Enum.take(-2)
    [month, day, id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")
    struct!(__MODULE__, [id: id, date: date, body: body, user: nil] ++ Map.to_list(attrs))
  end
end
