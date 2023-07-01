defmodule BanchanWeb.CommissionLive.Components.Attachments.ImageAttachment do
  @moduledoc """
  Simple component wrapper around a single attachment entry.
  """
  use BanchanWeb, :component

  slot default

  def render(assigns) do
    ~F"""
    <div class="h-16 w-16 relative sm:hover:scale-105 sm:hover:z-10 transition-all cursor-pointer">
      <#slot />
    </div>
    """
  end
end
