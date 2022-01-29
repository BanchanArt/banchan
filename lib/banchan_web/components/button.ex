defmodule BanchanWeb.Components.Button do
  @moduledoc """
  Generic button for Banchan. For form submissions, use BanchanWeb.Components.Form.Submit.
  """
  use BanchanWeb, :component

  prop is_primary, :boolean, default: true
  prop label, :string
  prop value, :any
  prop click, :event, required: true

  slot default

  def render(assigns) do
    ~F"""
    <button
      class={
        "btn",
        "text-center",
        "rounded-full",
        "py-1",
        "px-5 m-1",
        "btn-primary": @is_primary,
        "btn-secondary": !@is_primary
      }
      value={@value}
      type="button"
      :on-click={@click}
    >{@label}<#slot /></button>
    """
  end
end
