defmodule BanchanWeb.CommissionLive.New do
  @moduledoc """
  Live page for Commission Proposals
  """
  use BanchanWeb, :surface_view

  alias Banchan.Commissions.Commission
  alias BanchanWeb.Components.Layout

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    changeset = Commission.changeset(%Commission{}, %{})
    {:ok, assign(socket, changeset: changeset)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      idk yet
    </Layout>
    """
  end
end
