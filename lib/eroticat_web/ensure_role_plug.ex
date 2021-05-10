defmodule ErotiCatWeb.EnsureRolePlug do
  @moduledoc """
  This plug ensures that a user has a particular role.

  ## Example

      plug ErotiCatWeb.EnsureRolePlug, [:moderator, :admin]

      plug ErotiCatWeb.EnsureRolePlug, :creator

      plug ErotiCatWeb.EnsureRolePlug, ~w(moderator admin)a
  """
  import Plug.Conn, only: [halt: 1]

  alias ErotiCat.Users
  alias ErotiCatWeb.Router.Helpers, as: Routes
  alias Phoenix.Controller
  alias Plug.Conn
  alias Pow.Plug

  @doc false
  @spec init(any()) :: any()
  def init(config), do: config

  @doc false
  @spec call(Conn.t(), atom() | binary() | [atom()] | [binary()]) :: Conn.t()
  def call(conn, roles) do
    conn
    |> Plug.current_user()
    |> Users.has_role?(roles)
    |> maybe_halt(conn)
  end

  defp maybe_halt(true, conn), do: conn

  defp maybe_halt(_any, conn) do
    conn
    |> Controller.put_flash(:error, "Unauthorized access")
    |> Controller.redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end
end
