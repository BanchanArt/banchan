defmodule Banchan.Tags.Tag do
  @moduledoc """
  Global stats for Banchan-wide tags. These are managed through db triggers
  and not directly.
  """
  use Ecto.Schema

  schema "tags" do
    field :tag, :string
    field :count, :integer
  end
end
