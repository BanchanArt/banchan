defmodule BanchanWeb.Components.Button do
  @moduledoc """
  Generic button for Banchan. For form submissions, use BanchanWeb.Components.Form.Submit.
  """
  use BanchanWeb, :component

  prop primary, :boolean, default: true
  prop label, :string
  prop value, :any
  prop click, :event
  prop class, :css_class

  slot default

  def render(assigns) do
    ~F"""
    <button
      class={
        "btn",
        "text-center",
        "py-1",
        "px-5 m-1",
        @class,
        "btn-primary": @primary,
        "btn-secondary": !@primary
      }
      value={@value}
      type="button"
      :on-click={@click}
    >{@label}<#slot /></button>
    """
  end
end
