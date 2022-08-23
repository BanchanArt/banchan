defmodule Banchan.Accounts.InviteRequest do
  @moduledoc """
  An artist invite token signup request.
  """
  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Accounts.ArtistToken

  schema "invite_requests" do
    field :email, :string
    belongs_to :token, ArtistToken

    timestamps()
  end

  def changeset(request, attrs) do
    request
    |> cast(attrs, [:email])
    |> validate_email(:email)
  end

  def update_token_changeset(request, %ArtistToken{} = token) do
    request
    |> cast(%{token_id: token.id}, [:token_id])
    |> foreign_key_constraint(:token_id)
  end
end
