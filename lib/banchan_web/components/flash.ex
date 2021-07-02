defmodule Banchan.Components.Flash do
  @moduledoc """
  This is the Banchan homepage.
  """
  use BanchanWeb, :component

  prop flashes, :any

  def render(assigns) do
    ~F"""
    <p class="alert alert-info" role="alert"
        :on-click="lv:clear-flash"
        :values={key: "info"}>{live_flash(@flashes, :info)}</p>

    <p class="alert alert-danger" role="alert"
        :on-click="lv:clear-flash"
        :values={key: "error"}>{live_flash(@flashes, :error)}</p>
    """
  end
end
