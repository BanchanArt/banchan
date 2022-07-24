defmodule Banchan.Reports.ReportFilter do
  @moduledoc """
  Filters for listing/searching abuse reports.
  """
  defstruct [:query, :reporter, :investigator, :statuses, :order_by]

  @types %{
    query: :string,
    reporter: :string,
    investigator: :string,
    statuses:
      {:array,
       {:parameterized, Ecto.Enum, Ecto.Enum.init(values: [:new, :investigating, :resolved])}},
    order_by: {:parameterized, Ecto.Enum, Ecto.Enum.init(values: [:newest, :oldest, :default])}
  }

  import Ecto.Changeset

  def changeset(%__MODULE__{} = filter, attrs \\ %{}) do
    {filter, @types}
    |> cast(attrs, Map.keys(@types))
    |> validate_length(:query, max: 256)
    |> validate_length(:reporter, max: 100)
    |> validate_length(:investigator, max: 100)
  end
end
