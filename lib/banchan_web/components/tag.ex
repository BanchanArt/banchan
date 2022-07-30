defmodule BanchanWeb.Components.Tag do
  @moduledoc """
  Rendering of tag links.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop tag, :string, required: true
  prop type, :string, default: "offerings"

  # class="badge badge-lg badge-primary badge-outline cursor-pointer"
  @impl true
  def render(assigns) do
    ~F"""
    <LiveRedirect
      class="btn btn-xs btn-primary btn-outline rounded-full"
      to={Routes.discover_index_path(Endpoint, :index, @type, [{:q, @tag}])}
    >
      {@tag}
    </LiveRedirect>
    """
  end
end
