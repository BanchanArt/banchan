defmodule BanchanWeb.Components.Form.Checkbox do
  @moduledoc """
  Standard BanchanWeb checkbox input.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, Label, Checkbox}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop wrapper_class, :css_class
  prop class, :css_class

  slot default

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      <Label class="checkbox is-large">
        <div class={"control", @wrapper_class}>
          <InputContext :let={form: form, field: field}>
            <Checkbox
              class={
                @class,
                "is-large",
                "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
              }
              opts={@opts}
            />
          </InputContext>
        </div>
        <#slot />
      </Label>
      <ErrorTag class="help is-danger" />
    </Field>
    """
  end
end