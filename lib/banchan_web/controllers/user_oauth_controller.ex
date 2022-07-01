defmodule BanchanWeb.UserOAuthController do
  @moduledoc """
  Handles callbacks and such for OAuth authentication.
  """
  use BanchanWeb, :controller

  plug Ueberauth

  alias Banchan.Accounts
  alias BanchanWeb.UserAuth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    case Accounts.find_or_create_user(auth) do
      {:ok, user} ->
        UserAuth.log_in_user(conn, user)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_flash(
          :error,
          changeset.errors
          |> Enum.map_join(", ", fn {field, {err, _}} ->
            "#{Atom.to_string(field)}: #{err}"
          end)
        )
        |> redirect(to: "/")

      _ ->
        conn
        |> put_flash(:error, "Authentication failed")
        |> redirect(to: "/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Authentication failed")
    |> redirect(to: "/")
  end
end
