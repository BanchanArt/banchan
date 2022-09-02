defmodule Banchan.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Accounts.DisableHistory
  alias Banchan.Notifications.{UserNotification, UserNotificationSettings}
  alias Banchan.Studios.Studio
  alias Banchan.Uploads.Upload

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :email, :string
    field :handle, :string, autogenerate: {__MODULE__, :auto_username, []}
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :deactivated_at, :naive_datetime
    field :name, :string
    field :bio, :string
    field :totp_secret, :binary
    field :totp_activated, :boolean
    field :tags, {:array, :string}
    field :mature_ok, :boolean, default: false
    field :uncensored_mature, :boolean, default: false
    field :muted, :string
    field :available_invites, :integer, default: 0

    # Roles and moderation
    field :roles, {:array, Ecto.Enum}, values: [:system, :admin, :mod, :artist], default: []
    field :moderation_notes, :string
    has_one :disable_info, DisableHistory, where: [lifted_at: nil]
    has_many :disable_history, DisableHistory, preload_order: [desc: :disabled_at]

    # OAuth UIDs
    field :twitter_uid, :string
    field :google_uid, :string
    field :discord_uid, :string

    # Social handles
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

    belongs_to :header_img, Upload, on_replace: :nilify, type: :binary_id
    belongs_to :pfp_img, Upload, on_replace: :nilify, type: :binary_id
    belongs_to :pfp_thumb, Upload, on_replace: :nilify, type: :binary_id

    has_one :notification_settings, UserNotificationSettings

    has_many :notifications, UserNotification

    many_to_many :studios, Studio, join_through: "users_studios"

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
    |> validate_required([:email])
    |> validate_handle(:handle)
    |> validate_unique_email(:email)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  The same as above, but used for testing purposes only!

  This is used so that MFA settings can be set instantly.
  """
  def registration_test_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :handle,
      :email,
      :password,
      :roles,
      :confirmed_at,
      :totp_secret,
      :totp_activated
    ])
    |> validate_handle(:handle)
    |> validate_required([:email])
    |> validate_unique_email(:email)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
    |> unique_constraint(:handle)
  end

  def registration_oauth_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [
      :handle,
      :email,
      :name,
      :bio,
      :password,
      :confirmed_at,
      :twitter_uid,
      :twitter_handle,
      :google_uid,
      :discord_uid,
      :discord_handle
    ])
    |> validate_handle(:handle)
    |> validate_unique_email(:email)
    |> validate_bio()
    |> validate_name()
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
    |> unique_constraint(:handle)
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

  def roles_changeset(%__MODULE__{} = actor, %__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, [:roles])
    |> validate_roles(actor, user)
  end

  @doc """
  User changeset for admins to edit particular fields for users.
  """
  def admin_changeset(%__MODULE__{} = actor, %__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [
      :roles,
      :moderation_notes
    ])
    |> validate_roles(actor, user)
    |> validate_length(:moderation_notes, max: 500)
    |> validate_markdown(:moderation_notes)
  end

  @doc """
  A user changeset meant for general editing forms.
  """
  def profile_changeset(user, attrs \\ %{}) do
    attrs =
      if attrs["tags"] == "[]" do
        Map.put(attrs, "tags", [])
      else
        attrs
      end

    user
    |> cast(attrs, [
      :name,
      :bio,
      :tags,
      :pfp_img_id,
      :pfp_thumb_id,
      :header_img_id
    ])
    |> cast_socials(attrs)
    |> validate_socials()
    |> validate_name()
    |> validate_bio()
    |> validate_tags()
    |> foreign_key_constraint(:pfp_img_id)
    |> foreign_key_constraint(:pfp_thumb_id)
    |> foreign_key_constraint(:header_img_id)
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_unique_email(:email)
  end

  @doc """
  A user changeset for changing the handle.
  """
  def handle_changeset(user, attrs) do
    user
    |> cast(attrs, [:handle])
    |> validate_handle(:handle)
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
  User changeset for setting a TOTP token.
  """
  def totp_secret_changeset(user, attrs) do
    user
    |> cast(attrs, [:totp_secret, :totp_activated])
  end

  @doc """
  User changeset for setting maturity flag.
  """
  def maturity_changeset(user, attrs) do
    user
    |> cast(attrs, [:mature_ok, :uncensored_mature])
  end

  @doc """
  User changeset for setting muted words.
  """
  def muted_changeset(user, attrs) do
    user
    |> cast(attrs, [:muted])
    |> validate_length(:muted, max: 1000)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Changeset for deactivating a user account.
  """
  def deactivate_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, deactivated_at: now)
  end

  @doc """
  Changeset for reactivating a user.
  """
  def reactivate_changeset(user) do
    change(user, deactivated_at: nil)
  end

  @doc """
  Updates a user's artist invite count.
  """
  def update_invite_count_changeset(user, count) do
    user
    |> cast(%{available_invites: count}, [:available_invites])
    |> validate_number(:available_invites, greater_than_or_equal_to: 0)
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

  def system_registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:handle, :name, :bio, :password])
    |> validate_handle(:handle)
    |> validate_name()
    |> validate_bio()
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password([])
    |> put_change(:roles, [:system])
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp validate_roles(changeset, actor, user) do
    changeset
    |> validate_change(:roles, fn field, roles ->
      cond do
        :system in actor.roles ->
          []

        :admin in actor.roles ->
          []

        :mod in actor.roles && :admin not in roles ->
          []

        true ->
          [{field, "can't give user a role higher than your own"}]
      end
    end)
    |> validate_change(:roles, fn field, _ ->
      cond do
        actor.id == user.id ->
          []

        (:mod in actor.roles && :mod in user.roles) ||
          (:mod in actor.roles && :admin in user.roles) ||
            (:admin in actor.roles && :admin in user.roles) ->
          [{field, "can't edit roles for user with equal or higher privileges than you"}]

        true ->
          []
      end
    end)
  end
end
