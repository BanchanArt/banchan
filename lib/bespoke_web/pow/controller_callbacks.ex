defmodule BespokeWeb.Pow.ControllerCallbacks do
  @moduledoc false
  alias Plug.Conn
  alias Pow.Extension.Phoenix.ControllerCallbacks

  @live_socket_id_key :live_socket_id

  def before_respond(Pow.Phoenix.SessionController, :create, {:ok, conn}, config) do
    user = conn.assigns.current_user

    conn =
      conn
      |> Conn.put_session(:current_user_id, user.id)
      |> Conn.put_session(@live_socket_id_key, "users_sockets:#{user.id}")

    ControllerCallbacks.before_respond(
      Pow.Phoenix.SessionController,
      :create,
      {:ok, conn},
      config
    )
  end

  def before_respond(Pow.Phoenix.SessionController, :delete, {:ok, conn}, config) do
    live_socket_id = Conn.get_session(conn, @live_socket_id_key)
    BespokeWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})

    ControllerCallbacks.before_respond(
      Pow.Phoenix.SessionController,
      :delete,
      {:ok, conn},
      config
    )
  end

  defdelegate before_respond(controller, action, results, config), to: ControllerCallbacks

  defdelegate before_process(controller, action, results, config), to: ControllerCallbacks
end
