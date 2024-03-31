defmodule Banchan.Studios.PortfolioImage do
  @moduledoc """
  Schema for portfolio images associated with studios.

  DEPRECATED: This is no longer used, but is kept around for data migration
  purposes.
  """
  use Ecto.Schema

  alias Banchan.Studios.Studio
  alias Banchan.Uploads.Upload

  schema "studio_portfolio_images" do
    field :index, :integer

    belongs_to :studio, Studio
    belongs_to :upload, Upload, on_replace: :nilify, type: :binary_id

    timestamps()
  end
end
