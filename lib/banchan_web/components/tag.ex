defmodule BanchanWeb.Components.Tag do
  @moduledoc """
  Rendering of tag links.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop tag, :string, required: true
  prop link, :boolean, default: true
  prop type, :string, default: "offerings"

  # class="badge badge-lg badge-primary badge-outline cursor-pointer"
  @impl true
  def render(assigns) do
    ~F"""
    {#if @link}
      <LiveRedirect
        class="btn btn-xs btn-primary btn-outline rounded-full"
        to={Routes.discover_index_path(Endpoint, :index, @type, [{:q, @tag}])}
      >
        {@tag}
      </LiveRedirect>
    {#else}
      <div class="rounded-full badge badge-outline badge-primary font-semibold uppercase no-underline max-w-full">
        <p class="truncate" title={@tag}>{@tag}</p>
      </div>
    {/if}
    """
  end
end
