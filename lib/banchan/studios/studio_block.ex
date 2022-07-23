defmodule Banchan.Studios.StudioBlock do
  @moduledoc """
  An item in a studio's blocklist.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User
  alias Banchan.Studios.Studio

  schema "studio_block" do
    field :reason, :string

    belongs_to :studio, Studio
    belongs_to :user, User

    timestamps()
  end

  def changeset(block, attrs) do
    block
    |> cast(attrs, [:reason])
    |> validate_length(:reason, max: 500)
  end
end
