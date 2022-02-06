defmodule Banchan.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Banchan.Identities

  alias Banchan.Uploads.Upload

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :email, :string
    field :handle, :string, autogenerate: {__MODULE__, :auto_username, []}
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :name, :string
    field :bio, :string
    field :roles, {:array, Ecto.Enum}, values: [:admin, :mod, :creator]

    belongs_to :header_img, Upload, on_replace: :nilify
    belongs_to :pfp_img, Upload, on_replace: :nilify
    belongs_to :pfp_thumb, Upload, on_replace: :nilify

    many_to_many :studios, Banchan.Studios.Studio, join_through: "users_studios"

    timestamps()
  end

  def changeset(user, attrs) do
    user |> cast(attrs, [])
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:handle, :email, :password])
    |> validate_handle_unique(:handle)
    |> unique_constraint(:handle)
    |> validate_email()
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @spec login_changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def login_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
  end

  defp validate_handle(changeset) do
    changeset
    |> validate_required([:handle])
    |> validate_format(:handle, ~r/^[a-zA-Z0-9_]+$/,
      message: "only letters, numbers, and underscores allowed"
    )
    |> validate_length(:handle, min: 3, max: 16)
    |> validate_handle_unique(:handle)
    |> unique_constraint(:handle)
  end

  def auto_username do
    "user#{:rand.uniform(100_000_000)}"
  end

  defp validate_name(changeset) do
    changeset
    |> validate_length(:name, max: 32)
  end

  defp validate_bio(changeset) do
    changeset
    |> validate_length(:bio, max: 160)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Banchan.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset meant for general editing forms.
  """
  def profile_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:handle, :name, :bio])
    |> validate_required([:handle])
    |> validate_handle()
    |> validate_name()
    |> validate_bio()
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
  end

  @doc """
  A user changeset for changing the handle.
  """
  def handle_changeset(user, attrs) do
    user
    |> cast(attrs, [:handle])
    |> validate_handle()
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Pbkdf2.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Banchan.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  A user changeset for registering admins.
  """
  def admin_registration_changeset(user, attrs) do
    user
    |> registration_changeset(attrs)
    |> prepare_changes(&set_admin_role/1)
  end

  defp set_admin_role(changeset) do
    changeset
    |> put_change(:roles, [:admin])
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
