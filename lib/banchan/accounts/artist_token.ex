defmodule Banchan.Accounts.ArtistToken do
  @moduledoc """
  Invite token used to grant users the `:artist` role.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.{InviteRequest, User}

  @rand_size 32

  schema "artist_tokens" do
    field :token, :string
    belongs_to :generated_by, User
    belongs_to :used_by, User
    has_one :request, InviteRequest, foreign_key: :token_id

    timestamps()
  end

  def build_token do
    @rand_size
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  def used_by_changeset(token, attrs) do
    token
    |> cast(attrs, [:used_by_id])
    |> foreign_key_constraint(:used_by_id)
  end
end
