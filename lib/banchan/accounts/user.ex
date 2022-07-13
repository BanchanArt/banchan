defmodule Banchan.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  import Banchan.Validators

  alias Banchan.Accounts.DisableHistory
  alias Banchan.Identities
  alias Banchan.Notifications.{UserNotification, UserNotificationSettings}
  alias Banchan.Studios.Studio
  alias Banchan.Uploads.Upload

  @derive {Inspect, except: [:password]}
  schema "users" do
    # TODO: use trigger functions to track follower/following counts
    field :email, :string
    field :handle, :string, autogenerate: {__MODULE__, :auto_username, []}
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :name, :string
    field :bio, :string
    field :totp_secret, :binary
    field :totp_activated, :boolean
    field :tags, {:array, :string}

    # Roles and moderation
    field :roles, {:array, Ecto.Enum}, values: [:admin, :mod, :artist], default: []
    field :moderation_notes, :string
    has_one :disable_info, DisableHistory, where: [lifted_at: nil]
    has_many :disable_history, DisableHistory, preload_order: [desc: :disabled_at]

    # OAuth UIDs
    field :twitter_uid, :string
    field :google_uid, :string
    field :discord_uid, :string

    # Social handles
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
    |> validate_handle_unique(:handle)
    |> unique_constraint(:handle)
    |> validate_required([:email])
    |> validate_email()
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
    |> validate_handle_unique(:handle)
    |> unique_constraint(:handle)
    |> validate_roles(nil)
    |> validate_required([:email])
    |> validate_email()
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
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
      :google_uid,
      :discord_uid
    ])
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
  User changeset for admins to edit particular fields for users.
  """
  def admin_changeset(%__MODULE__{} = actor, %__MODULE__{} = user, attrs \\ %{}) do
    user
    |> cast(attrs, [
      :roles,
      :moderation_notes
    ])
    |> validate_roles(actor)
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
      :twitter_handle,
      :instagram_handle,
      :facebook_url,
      :furaffinity_handle,
      :discord_handle,
      :artstation_handle,
      :deviantart_handle,
      :tumblr_handle,
      :mastodon_handle,
      :twitch_channel,
      :picarto_channel,
      :pixiv_url,
      :pixiv_handle,
      :tiktok_handle,
      :artfight_handle
    ])
    |> validate_name()
    |> validate_bio()
    |> validate_tags()
    |> validate_socials()
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def validate_socials(changeset) do
    changeset
    |> validate_change(:twitter_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Twitter handle, without the @ sign."}]
      end
    end)
    |> validate_change(:instagram_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Instagram handle, without the @ sign."}]
      end
    end)
    |> validate_change(:facebook_url, fn field, url ->
      if String.match?(url, ~r/^https:\/\/(www\.)?facebook\.com\/.+$/) do
        []
      else
        [{field, "must be a valid Facebook URL."}]
      end
    end)
    |> validate_change(:furaffinity_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Furaffinity handle."}]
      end
    end)
    |> validate_change(:discord_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+#\d{4}$/) do
        []
      else
        [{field, "must be a valid Discord handle, including the number (myname#1234)."}]
      end
    end)
    |> validate_change(:artstation_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Artstation handle."}]
      end
    end)
    |> validate_change(:deviantart_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Deviantart handle."}]
      end
    end)
    |> validate_change(:tumblr_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Tumblr handle."}]
      end
    end)
    |> validate_change(:mastodon_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+@.+$/) do
        []
      else
        [
          {field,
           "must be a valid Mastodon handle, without the preceding @. For example: `foo@mastodon.social`."}
        ]
      end
    end)
    |> validate_change(:twitch_channel, fn field, channel ->
      if String.match?(channel, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Twitch channel name."}]
      end
    end)
    |> validate_change(:picarto_channel, fn field, channel ->
      if String.match?(channel, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Picarto channel name."}]
      end
    end)
    |> validate_change(:pixiv_url, fn field, url ->
      if String.match?(url, ~r/^https:\/\/www\.pixiv\.net\/en\/users\/\d+$/) do
        []
      else
        [{field, "must be a valid Pixiv URL."}]
      end
    end)
    |> validate_change(:pixiv_url, fn field, _ ->
      if Ecto.Changeset.fetch_field(changeset, :pixiv_handle) == :error do
        [{field, "Must provide both a pixiv handle and a pixiv url, or neither."}]
      else
        []
      end
    end)
    |> validate_change(:pixiv_handle, fn field, _ ->
      if Ecto.Changeset.fetch_field(changeset, :pixiv_url) == :error do
        [{field, "Must provide both a pixiv handle and a pixiv url, or neither."}]
      else
        []
      end
    end)
    |> validate_change(:pixiv_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Pixiv handle."}]
      end
    end)
    |> validate_change(:tiktok_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid TikTok handle, without the @ sign."}]
      end
    end)
    |> validate_change(:artfight_handle, fn field, handle ->
      if String.match?(handle, ~r/^[a-zA-Z0-9_]+$/) do
        []
      else
        [{field, "must be a valid Artfight handle, without the ~ sign."}]
      end
    end)
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_required([:email])
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
  User changeset for setting a TOTP token.

  Will fail if current TOTP is activated.
  """
  def totp_secret_changeset(user, attrs) do
    if user.totp_activated == true do
      {:error, :totp_activated}
    end

    user
    |> cast(attrs, [:totp_secret, :totp_activated])
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

  defp validate_roles(changeset, actor) do
    changeset
    |> validate_change(:roles, fn field, roles ->
      cond do
        is_nil(actor) ->
          []

        :admin in actor.roles ->
          []

        :mod in actor.roles && :admin not in roles ->
          []

        true ->
          [{field, "Can't give user a role higher than your own."}]
      end
    end)
  end
end
