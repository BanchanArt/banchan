defmodule BanchanWeb.Components.Flash do
  @moduledoc """
  Handles displaying flashes for a page.
  """
  use BanchanWeb, :component

  prop flashes, :any

  def render(assigns) do
    ~F"""
    <div class="flash-container">
      <p class="alert alert-info py-0" role="alert" :on-click="lv:clear-flash" :values={key: "info"}>{live_flash(@flashes, :info)}</p>

      <p class="alert alert-danger py-0" role="alert" :on-click="lv:clear-flash" :values={key: "error"}>{live_flash(@flashes, :error)}</p>
    </div>
    """
  end
end
