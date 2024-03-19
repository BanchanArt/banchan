defmodule Banchan.Works.WorkUpload do
  @moduledoc """
  Uploads belonging to Works. For media uploads, we also keep a thumbnailed
  preview.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  schema "work_uploads" do
    field :index, :integer
    field :comment, :string
    field :ref, :string, virtual: true
    belongs_to :work, Banchan.Works.Work
    belongs_to :upload, Banchan.Uploads.Upload, type: :binary_id
    belongs_to :preview, Banchan.Uploads.Upload, on_replace: :nilify, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(work_upload, attrs) do
    work_upload
    |> cast(attrs, [:index, :comment])
    |> validate_required([:index])
    |> validate_rich_text_length(:comment, max: 200)
  end
end
