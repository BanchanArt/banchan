defmodule BanchanWeb.EnsureEnabledPlug do
  @moduledoc """
  Ensures that only users that aren't disabled (with the `disabled_at` field)
  can access a given route.
  """
  import Plug.Conn

  alias Phoenix.Controller

  alias Banchan.Accounts
  alias Banchan.Repo

  alias BanchanWeb.Endpoint
  alias BanchanWeb.Router.Helpers, as: Routes

  @doc false
  @spec init(any()) :: any()
  def init(config), do: config

  @doc false
  def call(conn, _) do
    user_token = get_session(conn, :user_token)

    user =
      user_token && Accounts.get_user_by_session_token(user_token) |> Repo.preload(:disable_info)

    if is_nil(user) do
      maybe_halt(false, conn)
    else
      user
      |> enabled?()
      |> maybe_halt(conn)
    end
  end

  defp enabled?(user) when is_nil(user.disable_info), do: true
  defp enabled?(user) when is_nil(user.disable_info.disabled_until), do: false

  defp enabled?(user) do
    if NaiveDateTime.compare(NaiveDateTime.utc_now(), user.disable_info.disabled_until) == :gt do
      {:ok, _} = Accounts.enable_user(nil, user, "Disabled time frame expired.")
      true
    else
      false
    end
  end

  defp maybe_halt(true, conn), do: conn

  defp maybe_halt(_any, conn) do
    conn
    |> Controller.put_flash(:error, "You are not authorized to access this page.")
    |> Controller.redirect(to: disabled_path(conn))
    |> halt()
  end

  defp disabled_path(_conn), do: Routes.account_disabled_path(Endpoint, :show)
end
