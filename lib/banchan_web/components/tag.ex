defmodule BanchanWeb.Components.Tag do
  @moduledoc """
  Rendering of tag links.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop tag, :string, required: true
  prop link, :boolean, default: true
  prop type, :string, default: "offerings"

  # class="cursor-pointer badge badge-lg badge-primary badge-outline"
  @impl true
  def render(assigns) do
    ~F"""
    {#if @link}
      <LiveRedirect
        class="flex flex-row items-center max-w-full gap-1 px-2 py-1 text-xs font-semibold text-opacity-75 no-underline uppercase rounded-full cursor-pointer bg-opacity-10 h-fit w-fit hover:bg-opacity-20 active:bg-opacity-20 border-base-content border-opacity-10 hover:text-opacity-100 active:text-opacity-100 bg-base-content"
        to={Routes.discover_index_path(Endpoint, :index, @type, [{:q, @tag}])}
      >
        <span class="tracking-wide">{@tag}</span>
      </LiveRedirect>
    {#else}
      <div class="flex flex-row items-center max-w-full gap-1 px-2 py-1 text-xs font-semibold text-opacity-75 no-underline uppercase rounded-full bg-opacity-10 h-fit w-fit border-base-content border-opacity-10 bg-base-content">
        <p class="tracking-wide truncate" title={@tag}>{@tag}</p>
      </div>
    {/if}
    """
  end
end
