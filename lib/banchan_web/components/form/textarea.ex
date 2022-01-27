defmodule BanchanWeb.Components.Form.TextArea do
  @moduledoc """
  Banchan-specific TextArea.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :any

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      <Label class="label" />
      <div class="control">
        <InputContext :let={form: form, field: field}>
          <TextArea
            class={"textarea", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
            opts={@opts}
          />
        </InputContext>
      </div>
      <ErrorTag class="help is-danger" />
    </Field>
    """
  end
end
