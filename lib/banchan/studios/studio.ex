defmodule Banchan.Studios.Studio do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Studios.{Common, PortfolioImage, StudioBlock, StudioDisableHistory}
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
    field :featured, :boolean, default: false
    field :tags, {:array, :string}
    field :mature, :boolean, default: false
    field :archived_at, :naive_datetime
    field :deleted_at, :naive_datetime

    # Moderation etc
    field :moderation_notes, :string
    has_one :disable_info, StudioDisableHistory, where: [lifted_at: nil]
    has_many :disable_history, StudioDisableHistory, preload_order: [desc: :disabled_at]
    has_many :blocklist, StudioBlock, preload_order: [desc: :inserted_at]

    field :stripe_id, :string
    field :stripe_charges_enabled, :boolean
    field :stripe_details_submitted, :boolean

    field :platform_fee, :decimal,
      default: Application.compile_env!(:banchan, :default_platform_fee)

    belongs_to :header_img, Upload, type: :binary_id
    belongs_to :card_img, Upload, type: :binary_id

    has_many :portfolio_imgs, PortfolioImage,
      on_replace: :delete_if_exists,
      preload_order: [asc: :index]

    many_to_many :artists, Banchan.Accounts.User,
      join_through: "users_studios",
      where: [deactivated_at: nil]

    many_to_many :followers, Banchan.Accounts.User, join_through: "studio_followers"

    has_many :offerings, Banchan.Offerings.Offering, preload_order: [:asc, :index]

    field :website_url, :string
    field :twitter_handle, :string
    field :instagram_handle, :string
    field :facebook_url, :string
    field :furaffinity_handle, :string
    field :discord_handle, :string
    field :artstation_handle, :string
    field :deviantart_handle, :string
    field :tumblr_handle, :string
    field :mastodon_handle, :string
    field :twitch_channel, :string
    field :picarto_channel, :string
    field :pixiv_url, :string
    field :pixiv_handle, :string
    field :tiktok_handle, :string
    field :artfight_handle, :string

    timestamps()
  end

  @doc false
  def creation_changeset(studio, attrs) do
    studio
    |> cast(attrs, [
      :name,
      :handle,
      :about,
      :mature,
      :country,
      :default_currency,
      :payment_currencies
    ])
    |> validate_required([:name, :handle, :country, :default_currency, :payment_currencies])
    |> validate_length(:name, min: 4, max: 32)
    |> validate_length(:handle, min: 4, max: 16)
    |> validate_length(:about, max: 500)
    |> validate_default_currency(:default_currency, :payment_currencies)
    |> validate_handle(:handle)
  end

  def settings_changeset(studio, attrs) do
    studio
    |> cast(attrs, [
      :mature,
      :default_currency,
      :payment_currencies,
      :default_terms,
      :default_template
    ])
    |> validate_required([:default_currency, :payment_currencies])
    |> validate_markdown(:default_terms)
    |> validate_markdown(:default_template)
    |> validate_length(:default_terms, max: 1500)
    |> validate_length(:default_template, max: 1500)
    |> validate_default_currency(:default_currency, :payment_currencies)
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
      :card_img_id,
      :header_img_id
    ])
    |> cast_socials(attrs)
    |> validate_socials()
    |> validate_required([:name, :handle])
    |> validate_length(:name, min: 4, max: 32)
    |> validate_length(:handle, min: 4, max: 16)
    |> validate_length(:about, max: 500)
    |> validate_tags()
    |> validate_handle(:handle)
    |> foreign_key_constraint(:card_img_id)
    |> foreign_key_constraint(:header_img_id)
  end

  def portfolio_changeset(studio, images) do
    studio
    |> Ecto.Changeset.change()
    |> put_assoc(:portfolio_imgs, images)
  end

  def featured_changeset(studio, attrs) do
    studio
    |> cast(attrs, [:featured])
  end

  def admin_changeset(studio, attrs) do
    studio
    |> cast(attrs, [:platform_fee, :moderation_notes])
    |> validate_number(:platform_fee, less_than: 1)
    |> validate_markdown(:moderation_notes)
  end

  def archive_changeset(studio) do
    change(studio, archived_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  def unarchive_changeset(studio) do
    change(studio, archived_at: nil)
  end

  @doc """
  Changeset for soft-deleting a Studio.
  """
  def deletion_changeset(studio) do
    change(studio, deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
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
end
