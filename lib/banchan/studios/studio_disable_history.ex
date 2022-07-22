defmodule Banchan.Studios.StudioDisableHistory do
  @moduledoc """
  Historical data for disabled studios.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Accounts.User
  alias Banchan.Studios.Studio

  schema "studio_disable_history" do
    belongs_to :studio, Studio, on_replace: :nilify
    belongs_to :disabled_by, User, on_replace: :nilify
    field :disabled_at, :naive_datetime
    field :disabled_until, :naive_datetime
    field :disabled_reason, :string
    field :lifting_job_id, :integer
    field :lifted_reason, :string
    field :lifted_at, :naive_datetime
    belongs_to :lifted_by, User, on_replace: :nilify
  end

  def disable_changeset(history, attrs) do
    changeset =
      history
      |> cast(attrs, [
        :disabled_until,
        :disabled_reason
      ])
      |> put_change(:disabled_at, NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
      |> validate_required([:disabled_reason])
      |> validate_length(:disabled_reason, max: 500)

    changeset
    |> validate_change(:disabled_until, fn field, until ->
      if NaiveDateTime.compare(
           Ecto.Changeset.get_field(changeset, :disabled_at, NaiveDateTime.utc_now()),
           until
         ) != :lt do
        [{field, "Disabled-until time must be after the time when the user was disabled."}]
      else
        []
      end
    end)
  end

  def enable_changeset(history, attrs) do
    history
    |> cast(attrs, [:lifted_reason])
    |> validate_length(:lifted_reason, max: 500)
  end
end
