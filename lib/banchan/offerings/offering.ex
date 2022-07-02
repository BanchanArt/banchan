defmodule Banchan.Offerings.Offering do
  @moduledoc """
  Main module for Offerings, which are the offering/offering definitions in Banchan.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Commissions.Commission
  alias Banchan.Offerings.{GalleryImage, OfferingOption}
  alias Banchan.Studios.Studio
  alias Banchan.Uploads.Upload

  schema "offerings" do
    field :type, :string
    field :index, :integer
    field :name, :string
    field :description, :string
    field :open, :boolean, default: false
    field :slots, :integer
    field :max_proposals, :integer
    field :hidden, :boolean, default: true
    field :terms, :string
    field :template, :string
    field :archived_at, :naive_datetime

    belongs_to :studio, Studio
    belongs_to :card_img, Upload, on_replace: :nilify, type: :binary_id

    has_many :gallery_imgs, GalleryImage,
      on_replace: :delete_if_exists,
      preload_order: [asc: :index]

    has_many :commissions, Commission
    has_many :options, OfferingOption, on_replace: :delete_if_exists

    timestamps()
  end

  @doc false
  def changeset(offering, attrs) do
    offering
    |> cast(attrs, [
      :type,
      :index,
      :name,
      :description,
      :open,
      :slots,
      :max_proposals,
      :hidden,
      :terms,
      :template
    ])
    |> cast_assoc(:options)
    |> validate_format(:type, ~r/^[0-9a-z-]+$/,
      message: "Only lowercase alphanumerics and - are allowed."
    )
    |> validate_number(:slots, greater_than: 0)
    |> validate_number(:max_proposals, greater_than: 0)
    |> validate_markdown(:terms)
    |> validate_markdown(:template)
    |> validate_length(:type, max: 32)
    |> validate_length(:name, max: 50)
    |> validate_length(:description, max: 140)
    |> validate_length(:terms, max: 1500)
    |> validate_length(:template, max: 1500)
    |> validate_required([:type, :name, :description])
    |> unique_constraint([:type, :studio_id])
  end
end
