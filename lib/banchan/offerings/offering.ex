defmodule Banchan.Offerings.Offering do
  @moduledoc """
  Main module for Offerings, which are the offering/offering definitions in Banchan.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Commissions.Commission
  alias Banchan.Offerings.{GalleryImage, OfferingOption}
  alias Banchan.Payments
  alias Banchan.Payments.Currency
  alias Banchan.Repo
  alias Banchan.Studios.Studio
  alias Banchan.Uploads.Upload

  schema "offerings" do
    field :type, :string
    field :index, :integer
    field :name, :string
    field :description, :string
    field :open, :boolean, default: true
    field :slots, :integer
    field :max_proposals, :integer
    field :hidden, :boolean, default: false
    field :terms, :string
    field :template, :string
    field :archived_at, :naive_datetime
    field :tags, {:array, :string}
    field :mature, :boolean, default: false
    field :currency, Ecto.Enum, values: Currency.supported_currencies()
    field :deleted_at, :naive_datetime

    field :base_price, Money.Ecto.Composite.Type, virtual: true
    field :has_addons, :boolean, virtual: true
    field :used_slots, :integer, virtual: true
    field :user_subscribed?, :boolean, virtual: true
    field :gallery_uploads, {:array, Upload}, virtual: true

    belongs_to :studio, Studio
    belongs_to :card_img, Upload, on_replace: :nilify, type: :binary_id

    field :gallery_imgs_changed, :boolean, virtual: true, default: false

    has_many :gallery_imgs, GalleryImage,
      on_replace: :delete_if_exists,
      preload_order: [asc: :index]

    has_many :commissions, Commission
    has_many :options, OfferingOption, on_replace: :delete_if_exists

    timestamps()
  end

  @doc false
  def changeset(offering, attrs) do
    attrs =
      if attrs["tags"] == "[]" do
        Map.put(attrs, "tags", [])
      else
        attrs
      end

    offering
    |> cast(attrs, [
      :type,
      :index,
      :name,
      :description,
      :currency,
      :open,
      :slots,
      :max_proposals,
      :hidden,
      :terms,
      :template,
      :tags,
      :mature,
      :card_img_id,
      :studio_id,
      :gallery_imgs_changed
    ])
    |> cast_assoc(:options)
    |> validate_required([:type, :name, :description, :currency])
    |> validate_format(:type, ~r/^[0-9a-z-]+$/,
      message: "Only lowercase alphanumerics and - are allowed."
    )
    |> validate_number(:slots, greater_than: 0)
    |> validate_number(:max_proposals, greater_than: 0)
    |> validate_markdown(:description)
    |> validate_markdown(:terms)
    |> validate_markdown(:template)
    |> validate_length(:type, min: 4, max: 32)
    |> validate_length(:name, min: 4, max: 50)
    |> validate_length(:description, max: 500)
    |> validate_length(:terms, max: 1500)
    |> validate_length(:template, max: 1500)
    |> validate_option_currencies()
    |> validate_total()
    |> validate_tags()
    |> unsafe_validate_unique([:type, :studio_id], Repo)
    |> validate_length(:tags, max: 5)
    |> foreign_key_constraint(:card_img_id)
    |> unique_constraint([:type, :studio_id])
  end

  def validate_option_currencies(changeset) do
    curr = fetch_field!(changeset, :currency)

    changeset
    |> validate_change(:options, fn _, opts ->
      if opts
         |> Enum.filter(&(&1.action in [:update, :insert]))
         |> Enum.all?(fn opt ->
           !opt.valid? || (get_field(opt, :price) && fetch_field!(opt, :price).currency == curr)
         end) do
        []
      else
        [{:options, "All options must use the configured currency on the offering."}]
      end
    end)
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def validate_total(changeset) do
    curr = fetch_field!(changeset, :currency)
    min = Payments.minimum_release_amount() |> Payments.convert_money(curr)
    max = Payments.maximum_release_amount() |> Payments.convert_money(curr)

    changeset
    |> validate_change(:options, fn _, opts ->
      opts = opts |> Enum.filter(&(&1.action in [:update, :insert]))

      base_total =
        opts
        |> Enum.reduce(Money.new(0, curr), fn opt, acc ->
          if opt.valid? && get_field(opt, :default) && get_field(opt, :price) do
            Money.add(acc, fetch_field!(opt, :price))
          else
            acc
          end
        end)

      any_overflow? =
        opts
        |> Enum.any?(fn opt ->
          opt.valid? && !get_field(opt, :default) && get_field(opt, :price) &&
            Payments.cmp_money(Money.add(fetch_field!(opt, :price), base_total), max) in [:gt]
        end)

      cond do
        Payments.cmp_money(base_total, max) in [:gt] || any_overflow? ->
          [
            {:options,
             "The maximum billable amount for commissions is #{Payments.print_money(max)}."}
          ]

        Payments.cmp_money(base_total, min) in [:lt] ->
          [
            {:options,
             "You must have enough 'Always Included' options to add up to at least #{Payments.print_money(min)}."}
          ]

        true ->
          []
      end
    end)
  end

  @doc """
  Changeset for soft-deleting an offering.
  """
  def deletion_changeset(offering) do
    change(offering, deleted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end
end
