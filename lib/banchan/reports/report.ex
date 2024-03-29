defmodule Banchan.Reports.Report do
  @moduledoc """
  Banchan content report.
  """
  use Ecto.Schema

  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "reports" do
    field :message, Banchan.Ecto.RichText
    field :uri, :string
    field :status, Ecto.Enum, values: [:new, :investigating, :resolved], default: :new
    field :notes, Banchan.Ecto.RichText
    field :tags, {:array, :string}

    belongs_to :reporter, User, on_replace: :nilify
    belongs_to :investigator, User, on_replace: :nilify

    timestamps()
  end

  def creation_changeset(report, attrs) do
    report
    |> cast(attrs, [:message, :uri])
    |> validate_rich_text_length(:message, max: 420)
    |> validate_length(:uri, max: 420)
  end

  def update_changeset(report, attrs) do
    report
    |> cast(attrs, [:status, :notes, :investigator_id])
    |> validate_rich_text_length(:notes, max: 2000)
    |> foreign_key_constraint(:investigator_id)
  end
end
