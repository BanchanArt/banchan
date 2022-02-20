defmodule BanchanWeb.StudioLive.Components.TabButton do
  @moduledoc """
  Component for the tab links in the Studio page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop tab_name, :atom, required: true
  prop current_tab, :atom, required: true
  prop label, :string, required: true
  prop to, :string, required: true

  def render(assigns) do
    ~F"""
    <LiveRedirect
      label={@label}
      class={
        "tab",
        "tab-lifted",
        "text-center",
        "flex-1",
        "tab-active": @current_tab == @tab_name,
        "bg-base-200": @current_tab != @tab_name
      }
      to={@to}
    />
    """
  end
end
