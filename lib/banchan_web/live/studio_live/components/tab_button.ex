defmodule BanchanWeb.StudioLive.Components.TabButton do
  @moduledoc """
  Component for the tab links in the Studio page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  alias BanchanWeb.Endpoint

  prop studio, :struct, required: true
  prop tab, :any, required: true
  prop live_action, :any, required: true
  prop label, :string, required: true

  def render(assigns) do
    ~F"""
      <LivePatch
        label={@label}
        class={"tab", "tab-bordered", "bg-opacity-60",
               "text-center", "rounded-t-lg", "text-secondary-content",
               "tab-active": @live_action == @tab,
               "bg-primary": @live_action != @tab,
               "bg-primary-focus": @live_action == @tab}
        to={Routes.studio_show_path(Endpoint, @tab, @studio.handle)} />
    """
  end
end
