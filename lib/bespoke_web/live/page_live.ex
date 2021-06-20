defmodule BespokeWeb.PageLive do
  @moduledoc """
  Bespoke Homepage
  """
  use BespokeWeb, :live_view
  alias BespokeWeb.LiveHelpers
  require Logger

  @impl true
  def mount(_params, session, socket) do
    {:ok, LiveHelpers.assign_defaults(socket, session)}
  end
end
