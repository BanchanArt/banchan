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
  prop disabled, :boolean, default: false
  prop opts, :keyword, default: []

  slot default

  def render(assigns) do
    ~F"""
    <button
      class={
        "btn",
        "btn-loadable",
        "text-center",
        @class,
        "btn-primary": @primary
      }
      value={@value}
      type="button"
      disabled={@disabled}
      :on-click={@click}
      {...@opts}
    >{@label}<#slot /></button>
    """
  end
end
