defmodule ErotiCatWeb.PageLive do
  @moduledoc """
  ErotiCat Homepage
  """
  use ErotiCatWeb, :live_view
  alias ErotiCatWeb.LiveHelpers
  require Logger

  @impl true
  def mount(_params, session, socket) do
    {:ok, LiveHelpers.assign_defaults(socket, session)}
  end
end
