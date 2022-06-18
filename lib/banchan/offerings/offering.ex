defmodule Banchan.Offerings.Offering do
  @moduledoc """
  Main module for Offerings, which are the offering/offering definitions in Banchan.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Commissions.Commission
  alias Banchan.Offerings.OfferingOption
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

    belongs_to :card_img, Upload, on_replace: :nilify, type: :binary_id
    belongs_to :studio, Studio
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
    |> validate_required([:type, :name, :description])
    |> unique_constraint([:type, :studio_id])
  end

  defp validate_markdown(changeset, field) do
    validate_change(changeset, field, fn _, data ->
      if data == HtmlSanitizeEx.markdown_html(data) do
        []
      else
        [{field, "Disallowed HTML detected. Some tags, like <script>, are not allowed."}]
      end
    end)
  end
end
