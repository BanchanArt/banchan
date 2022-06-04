defmodule Banchan.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Identities

  alias Banchan.Uploads.Upload

  schema "studios" do
    field :name, :string
    field :handle, :string
    field :description, :string
    field :summary, :string
    field :default_terms, :string
    field :default_template, :string

    field :stripe_id, :string
    field :stripe_charges_enabled, :boolean
    field :stripe_details_submitted, :boolean

    field :platform_fee, :decimal,
      default: Application.fetch_env!(:banchan, :default_platform_fee)

    belongs_to :header_img, Upload, type: :binary_id
    belongs_to :card_img, Upload, type: :binary_id

    many_to_many :artists, Banchan.Accounts.User, join_through: "users_studios"

    has_many :offerings, Banchan.Offerings.Offering, preload_order: [:asc, :index]

    timestamps()
  end

  @doc false
  def profile_changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name, :handle, :description, :summary, :default_terms, :default_template])
    |> validate_required([:name, :handle])
    |> validate_markdown(:default_terms)
    |> validate_markdown(:default_template)
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
