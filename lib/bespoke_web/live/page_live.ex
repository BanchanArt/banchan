defmodule BespokeWeb.PageLive do
  @moduledoc """
  Bespoke Homepage
  """
  use BespokeWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    {:ok, assign(socket, query: "", results: %{})}
  end
end
