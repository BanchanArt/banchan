defmodule Banchan.Offerings.Offering do
  @moduledoc """
  Main module for Offerings, which are the offering/offering definitions in Banchan.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Offerings.OfferingOption
  alias Banchan.Studios.Studio

  schema "offerings" do
    field :type, :string
    field :index, :integer
    field :name, :string
    field :description, :string
    field :open, :boolean, default: false
    field :base_price, Money.Ecto.Composite.Type
    field :terms, :string

    belongs_to :studio, Studio
    has_many :options, OfferingOption, on_replace: :delete_if_exists

    timestamps()
  end

  @doc false
  def changeset(offering, attrs) do
    offering
    |> cast(attrs, [:type, :index, :name, :description, :open, :base_price, :terms])
    |> cast_assoc(:options)
    # TODO: Upper limit?
    |> validate_money(:base_price)
    # TODO: validate terms and that they parse.
    |> validate_format(:type, ~r/^[0-9a-z-]+$/,
      message: "Only lowercase alphanumerics and - are allowed."
    )
    |> validate_markdown(:terms)
    |> validate_required([:type, :name, :description])
    |> unique_constraint([:type, :studio_id])
  end

  defp validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount > 0 -> []
      _, _ -> [{field, "must be greater than 0"}]
    end)
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
