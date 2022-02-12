defmodule Banchan.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Banchan.Identities

  schema "studios" do
    field :name, :string
    field :handle, :string
    field :description, :string
    field :header_img, :string
    field :card_img, :string
    field :summary, :string
    field :default_terms, :string

    field :stripe_id, :string
    field :stripe_charges_enabled, :boolean
    field :stripe_details_submitted, :boolean

    many_to_many :artists, Banchan.Accounts.User, join_through: "users_studios"

    has_many :offerings, Banchan.Offerings.Offering, preload_order: [:asc, :index]

    timestamps()
  end

  @doc false
  def changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name, :handle, :description, :summary, :default_terms])
    |> validate_required([:name, :handle])
    |> validate_handle_unique(:handle)
  end

  defp validate_handle_unique(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn current_field, value ->
      if Identities.validate_uniqueness_of_handle(value) do
        []
      else
        [{current_field, "already exists"}]
      end
    end)
  end
end
