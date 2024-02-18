defmodule Banchan.Works.Work do
  @moduledoc """
  Works are collections of uploads that can be put on the spotlight and
  associated with various other entities. On the site, they have dedicated
  pages that can be shared with others, and can lead viewers to Offerings.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  schema "works" do
    field :public_id, :string, autogenerate: {__MODULE__, :rand_id, []}
    field :title, :string
    field :description, :string
    field :tags, {:array, :string}
    field :mature, :boolean, default: false
    field :private, :boolean, default: false
    field :upload_count, :integer, virtual: true
    belongs_to :studio, Banchan.Studios.Studio
    belongs_to :client, Banchan.Accounts.User, on_replace: :nilify
    belongs_to :offering, Banchan.Offerings.Offering, on_replace: :nilify
    belongs_to :commission, Banchan.Commissions.Commission, on_replace: :nilify

    has_many :uploads, Banchan.Works.WorkUpload,
      on_replace: :delete_if_exists,
      preload_order: [asc: :index]

    timestamps()
  end

  def changeset(work, attrs) do
    attrs =
      if attrs["tags"] == "[]" do
        Map.put(attrs, "tags", [])
      else
        attrs
      end

    work
    |> cast(attrs, [:title, :description, :tags, :upload_count, :private, :mature])
    |> validate_required([:title, :upload_count])
    |> validate_length(:title, min: 3, max: 50)
    |> validate_number(:upload_count,
      greater_than_or_equal_to: 1,
      less_than_or_equal_to: 10,
      message: "must include between 1 and 10 uploads"
    )
    |> validate_rich_text_length(:description, max: 500)
    |> validate_tags()
    |> validate_length(:tags, max: 5)
  end

  def rand_id() do
    :crypto.strong_rand_bytes(10) |> Base.url_encode64(padding: false)
  end
end
