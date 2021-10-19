defmodule BanchanWeb.DispatchController do
  use BanchanWeb, :controller

  alias Banchan.Accounts.User
  alias Banchan.Identities
  alias Banchan.Studios.Studio

  def dispatch(conn, %{"handle" => handle}) do
    {:ok, found} = Identities.get_user_or_studio_by_handle(handle)

    case found do
      %User{} ->
        conn
        |> redirect(to: Routes.denizen_show_path(conn, :show, handle))

      %Studio{} ->
        conn
        |> redirect(to: Routes.studio_show_path(conn, :show, handle))
    end
  end
end
