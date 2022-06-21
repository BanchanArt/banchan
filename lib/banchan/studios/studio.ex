defmodule Banchan.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Identities

  alias Banchan.Uploads.Upload

  # https://stripe.com/docs/connect/cross-border-payouts#supported-countries
  # But also the US.
  @supported_countries [
    "Antigua and Barbuda": :AG,
    Argentina: :AR,
    Australia: :AU,
    Austria: :AT,
    Bahrain: :BH,
    Bangladesh: :BD,
    Belgium: :BE,
    Benin: :BJ,
    Bolivia: :BO,
    Bulgaria: :BG,
    Canada: :CA,
    Chile: :CL,
    Colombia: :CO,
    "Costa Rica": :CR,
    "Côte d'Ivoire": :CI,
    Croatia: :HR,
    Cyprus: :CY,
    "Czech Republic": :CZ,
    Denmark: :DK,
    "Dominican Republic": :DO,
    Egypt: :EG,
    Estonia: :EE,
    Finland: :FI,
    France: :FR,
    Gambia: :GM,
    Germany: :DE,
    Ghana: :GH,
    Greece: :GR,
    Guatemala: :GT,
    Guyana: :GY,
    "Hong Kong": :HK,
    Hungary: :HU,
    Iceland: :IS,
    India: :IN,
    Indonesia: :ID,
    Ireland: :IE,
    Israel: :IL,
    Italy: :IT,
    Jamaica: :JM,
    Japan: :JP,
    Kenya: :KE,
    Kuwait: :KW,
    Latvia: :LV,
    Liechtenstein: :LI,
    Lithuania: :LT,
    Luxembourg: :LU,
    Malta: :MT,
    Mauritius: :MU,
    Mexico: :MX,
    Monaco: :MC,
    Morocco: :MA,
    Namibia: :NA,
    Netherlands: :NL,
    "New Zealand": :NZ,
    Niger: :NE,
    Norway: :NO,
    Paraguay: :PY,
    Peru: :PE,
    Philippines: :PH,
    Poland: :PL,
    Portugal: :PT,
    Romania: :RO,
    "San Marino": :SM,
    "Saudi Arabia": :SA,
    Senegal: :SN,
    Serbia: :RS,
    Singapore: :SG,
    Slovakia: :SK,
    Slovenia: :SI,
    "South Africa": :ZA,
    "South Korea": :KR,
    Spain: :ES,
    "St. Lucia": :LC,
    Sweden: :SE,
    Switzerland: :CH,
    Thailand: :TH,
    "Trinidad and Tobago": :TT,
    Tunisia: :TN,
    Turkey: :TR,
    "United Arab Emirates": :AE,
    "United Kingdom": :UK,
    "United States": :US,
    Uruguay: :UY
  ]

  schema "studios" do
    field :name, :string
    field :handle, :string
    field :description, :string
    field :summary, :string
    field :default_terms, :string
    field :default_template, :string
    field :country, Ecto.Enum, values: @supported_countries |> Keyword.values()

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
  def creation_changeset(studio, attrs) do
    studio
    |> cast(attrs, [:name, :handle, :description, :country])
    |> validate_required([:name, :handle, :country])
    |> validate_handle_unique(:handle)
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

  def supported_countries() do
    @supported_countries
  end
end
