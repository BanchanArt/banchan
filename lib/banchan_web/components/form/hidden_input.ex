defmodule BanchanWeb.Components.Form.HiddenInput do
  @moduledoc """
  Wrapper for Surface.Components.Form.HiddenInput.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{Field, HiddenInput}

  prop name, :any
  prop value, :any
  prop opts, :any, default: []

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      <HiddenInput value={@value} opts={@opts} />
    </Field>
    """
  end
end
