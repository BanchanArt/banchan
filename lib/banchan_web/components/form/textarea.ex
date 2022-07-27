defmodule BanchanWeb.Components.Form.TextArea do
  @moduledoc """
  Banchan-specific TextArea.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop label, :string
  prop show_label, :boolean, default: true
  prop info, :string
  prop wrapper_class, :css_class
  prop rows, :number
  prop class, :css_class
  prop change, :event

  slot left
  slot right

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      {#if @show_label}
        <InputContext assigns={assigns} :let={field: field}>
          <Label class="label">
            <span class="label-text">
              {@label || Phoenix.Naming.humanize(field)}
              {#if @info}
                <div class="tooltip" data-tip={@info}>
                  <i class="fas fa-info-circle" />
                </div>
              {/if}
            </span>
          </Label>
        </InputContext>
      {/if}
      <div class="flex flex-col">
        <div class="flex flex-row gap-2">
          <div class={"control w-full", @wrapper_class}>
            <#slot name="left" />
            <InputContext :let={form: form, field: field}>
              <TextArea
                class={
                  "textarea",
                  "textarea-bordered",
                  "h-40",
                  "w-full",
                  @class,
                  "textarea-error": !Enum.empty?(Keyword.get_values(form.errors, field))
                }
                opts={[{:phx_debounce, "200"} | @opts]}
              />
            </InputContext>
            <#slot name="right" />
          </div>
        </div>
        <ErrorTag class="help text-error" />
      </div>
    </Field>
    """
  end
end
