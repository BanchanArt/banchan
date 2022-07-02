defmodule Banchan.Commissions.CommentHistory do
  @moduledoc """
  Historical data for comments
  """
  use Ecto.Schema

  alias Banchan.Accounts.User
  alias Banchan.Commissions.Event

  schema "comment_history" do
    field :text, :string
    field :written_at, :naive_datetime
    belongs_to :event, Event
    belongs_to :changed_by, User
  end
end
