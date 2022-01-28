defmodule BanchanWeb.Components.Form.TextInput do
  @moduledoc """
  Banchan-specific TextInput.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextInput}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :any
  prop class, :any

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      <Label class="label" />
      <div class="control">
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
      </div>
      <ErrorTag class="help is-danger" />
    </Field>
    """
  end
end
