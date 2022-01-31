defmodule BanchanWeb.Components.Form.Checkbox do
  @moduledoc """
  Standard BanchanWeb checkbox input.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{Checkbox, ErrorTag, Field, Label}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop wrapper_class, :css_class
  prop class, :css_class
  prop label, :string

  slot default

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      <Label class={"checkbox is-large control", @wrapper_class}>
        <InputContext :let={form: form, field: field}>
          <Checkbox
            class={
              @class,
              "checkbox",
              "checkbox-primary",
              "is-large",
              "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
            }
            opts={@opts}
          />
        </InputContext>
        <#slot>{@label}</#slot>
      </Label>
      <ErrorTag class="help is-danger" />
    </Field>
    """
  end
end
