defmodule BanchanWeb.Components.Form.Checkbox do
  @moduledoc """
  Standard BanchanWeb checkbox input.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, ErrorTag, Field, Label}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop wrapper_class, :css_class
  prop class, :css_class
  prop label, :string
  prop value, :any
  prop info, :string
  prop caption, :string
  prop form, :form, from_context: {Form, :form}

  slot default

  def render(assigns) do
    ~F"""
    <Field class="form-control" name={@name}>
      <Label class={"label gap-2 justify-start cursor-pointer", @wrapper_class}>
        <Checkbox
          value={@value}
          class={
            @class,
            "checkbox",
            "checkbox-primary ring-primary focus:ring-primary",
            "checkbox-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
          }
          opts={@opts}
        />
        <div class="flex flex-row items-center gap-1 px-2 label-text">
          <#slot>{@label}</#slot>
          {#if @info}
            <div class="tooltip tooltip-right" data-tip={@info}>
              <Icon
                name="info"
                size="4"
                label="tooltip"
                class="opacity-50 hover:opacity-100 active:opacity-100"
              />
            </div>
          {/if}
        </div>
      </Label>
      <ErrorTag class="help text-error" />
      {#if @caption}
        <div class="text-sm text-opacity-50 help text-base-content">
          {@caption}
        </div>
      {/if}
    </Field>
    """
  end
end
