defmodule BanchanWeb.Components.Form.TextArea do
  @moduledoc """
  Banchan-specific TextArea.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop label, :string
  prop show_label, :boolean, default: true
  prop info, :string
  prop wrapper_class, :css_class
  prop rows, :number
  prop class, :css_class
  prop change, :event
  prop form, :form, from_context: {Form, :form}

  slot left
  slot right

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      {#if @show_label}
        <Label class="label">
          <span class="flex flex-row items-center gap-1 label-text">
            {@label || Phoenix.Naming.humanize(@name)}
            {#if @info}
              <div class="tooltip" data-tip={@info}>
                <Icon name="info" size="4" label="tooltip" />
              </div>
            {/if}
          </span>
        </Label>
      {/if}
      <div class="flex flex-col">
        <div class="flex flex-row gap-2">
          <div class={"control w-full", @wrapper_class}>
            <#slot {@left} />
            <TextArea
              class={
                "textarea",
                "textarea-bordered",
                "h-40",
                "w-full",
                @class,
                "textarea-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
              }
              opts={[{:phx_debounce, "200"} | @opts]}
            />
            <#slot {@right} />
          </div>
        </div>
        <ErrorTag class="help text-error" />
      </div>
    </Field>
    """
  end
end
