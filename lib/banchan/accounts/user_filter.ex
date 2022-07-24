defmodule Banchan.Accounts.UserFilter do
  @moduledoc """
  Query filter for user listing.
  """
  defstruct [:query]

  @types %{
    query: :string
  }

  import Ecto.Changeset

  def changeset(%__MODULE__{} = filter, attrs \\ %{}) do
    {filter, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_length(:query, max: 200)
  end
end
