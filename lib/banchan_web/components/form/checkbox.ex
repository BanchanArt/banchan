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
  prop value, :any
  prop info, :string

  slot default

  def render(assigns) do
    ~F"""
    <Field class="form-control" name={@name}>
      <Label class={"label cursor-pointer", @wrapper_class}>
        <div class="label-text px-2">
          <#slot>{@label}</#slot>
          {#if @info}
            <div class="tooltip" data-tip={@info}>
              <i class="fas fa-info-circle" />
            </div>
          {/if}
        </div>
        <InputContext :let={form: form, field: field}>
          <Checkbox
            value={@value}
            class={
              @class,
              "checkbox",
              "checkbox-primary",
              "checkbox-error": !Enum.empty?(Keyword.get_values(form.errors, field))
            }
            opts={@opts}
          />
        </InputContext>
      </Label>
      <ErrorTag class="help text-error" />
    </Field>
    """
  end
end
