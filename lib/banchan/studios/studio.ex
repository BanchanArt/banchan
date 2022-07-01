defmodule Banchan.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Identities
  alias Banchan.Studios.{Common, PortfolioImage}
  alias Banchan.Uploads.Upload

  schema "studios" do
    field :name, :string
    field :handle, :string
    field :about, :string
    field :default_terms, :string
    field :default_template, :string
    field :country, Ecto.Enum, values: Common.supported_countries() |> Keyword.values()
    field :default_currency, Ecto.Enum, values: Common.supported_currencies()
    field :payment_currencies, {:array, Ecto.Enum}, values: Common.supported_currencies()
    field :tags, {:array, :string}

    field :stripe_id, :string
    field :stripe_charges_enabled, :boolean
    field :stripe_details_submitted, :boolean

    field :platform_fee, :decimal,
      default: Application.fetch_env!(:banchan, :default_platform_fee)

    belongs_to :header_img, Upload, type: :binary_id
    belongs_to :card_img, Upload, type: :binary_id

    has_many :portfolio_imgs, PortfolioImage,
      on_replace: :delete_if_exists,
      preload_order: [asc: :index]

    many_to_many :artists, Banchan.Accounts.User, join_through: "users_studios"

    has_many :offerings, Banchan.Offerings.Offering, preload_order: [:asc, :index]

    timestamps()
  end

  @doc false
  def creation_changeset(studio, attrs) do
    studio
    |> cast(attrs, [
      :name,
      :handle,
      :about,
      :country,
      :default_currency,
      :payment_currencies
    ])
    |> validate_required([:name, :handle, :country, :default_currency, :payment_currencies])
    |> validate_markdown(:about)
    |> validate_default_currency(:default_currency, :payment_currencies)
    |> validate_handle_unique(:handle)
  end

  @doc false
  def profile_changeset(studio, attrs) do
    attrs =
      if attrs["tags"] == "[]" do
        Map.put(attrs, "tags", [])
      else
        attrs
      end

    studio
    |> cast(attrs, [
      :name,
      :handle,
      :about,
      :tags,
      :default_currency,
      :payment_currencies,
      :default_terms,
      :default_template
    ])
    |> validate_required([:name, :handle, :default_currency, :payment_currencies])
    |> validate_markdown(:about)
    |> validate_tags()
    |> validate_markdown(:default_terms)
    |> validate_markdown(:default_template)
    |> validate_default_currency(:default_currency, :payment_currencies)
    |> validate_handle_unique(:handle)
  end

  def portfolio_changeset(studio, images) do
    studio
    |> Ecto.Changeset.change()
    |> put_assoc(:portfolio_imgs, images)
  end

  defp validate_default_currency(changeset, default_field, currencies_field)

  defp validate_default_currency(changeset, default_field, currencies_field) do
    validate_change(changeset, default_field, fn _, value ->
      case fetch_field(changeset, currencies_field) do
        {:changes, currencies} when is_list(currencies) ->
          if value in currencies do
            []
          else
            [{default_field, "Must be one of the selected payment currencies."}]
          end

        _ ->
          []
      end
    end)
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

  def validate_tags(changeset) do
    changeset
    |> validate_change(:tags, fn field, tags ->
      if tags |> Enum.map(&String.downcase/1) ==
           tags |> Enum.map(&String.downcase/1) |> Enum.uniq() do
        []
      else
        [{field, "cannot have duplicate tags."}]
      end
    end)
    |> validate_change(:tags, fn field, tags ->
      if Enum.count(tags) > 10 do
        [{field, "cannot have more than 10 tags."}]
      else
        []
      end
    end)
    |> validate_change(:tags, fn field, tags ->
      if Enum.all?(tags, fn tag ->
           String.match?(tag, ~r/^.{0,100}$/)
         end) do
        []
      else
        [{field, "Tags can only be up to 100 characters long."}]
      end
    end)
  end
end
