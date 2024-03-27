defmodule BanchanWeb.Components.Form.HiddenInput do
  @moduledoc """
  Wrapper for Surface.Components.Form.HiddenInput.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, HiddenInput}

  prop name, :any
  prop value, :any
  prop opts, :any, default: []

  def render(assigns) do
    ~F"""
    <Field class="grid grid-cols-1 gap-2 field" name={@name}>
      <HiddenInput value={@value} opts={@opts} />
      <ErrorTag class="help text-error" />
    </Field>
    """
  end
end
