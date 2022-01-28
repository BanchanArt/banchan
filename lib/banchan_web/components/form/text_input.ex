defmodule BanchanWeb.Components.Form.TextInput do
  @moduledoc """
  Banchan-specific TextInput.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextInput}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :any
  prop wrapper_class, :css_class

  slot left
  slot right
  slot default

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      <Label class="label" />
      <div class={"control", @wrapper_class}>
        <#slot name="left" />
        <InputContext :let={form: form, field: field}>
          <TextInput
            class={
              "input",
              "input-primary",
              "input-bordered",
              "input-sm",
              "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
            }
            opts={@opts}
          />
        </InputContext>
        <#slot name="right" />
      </div>
      <ErrorTag class="help is-danger" />
    </Field>
    """
  end
end
