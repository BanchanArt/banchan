defmodule BanchanWeb.CurrentPageHook do
  @moduledoc """
  Takes care of adding the @current_page variable to the assigns map. Mainly
  used for the navbar.
  """
  import Phoenix.LiveView

  alias Surface.Components.Context

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(
       :set_current_page,
       :handle_params,
       fn _params, uri, socket ->
         {:cont, Context.put(socket, current_page: URI.parse(uri).path)}
       end
     )}
  end
end
