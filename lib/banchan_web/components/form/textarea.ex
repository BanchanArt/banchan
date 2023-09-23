defmodule BanchanWeb.Components.Form.TextArea do
  @moduledoc """
  Banchan-specific TextArea.
  """
  use BanchanWeb, :component

  # alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop label, :string
  prop show_label, :boolean, default: true
  prop focus_label_first, :boolean, default: true
  prop info, :string
  prop caption, :string
  prop wrapper_class, :css_class
  prop rows, :number
  prop class, :css_class
  prop change, :event
  prop form, :form, from_context: {Form, :form}

  slot label_end
  slot left
  slot right
  slot caption_end

  def render(assigns) do
    ~F"""
    <Field class="relative grid grid-cols-1 gap-2 field" name={@name}>
      {#if @show_label}
        <div class={
          "flex flex-row items-center gap-4",
          "justify-between": slot_assigned?(:label_end) && @focus_label_first
        }>
          <Label class="p-0 label">
            <span class="flex flex-row items-center gap-1 label-text">
              {@label || Phoenix.Naming.humanize(@name)}
              {!--
              {#if @info}
                <div class="tooltip tooltip-right" data-tip={@info}>
                  <Icon
                    name="info"
                    size="4"
                    label="tooltip"
                    class="opacity-50 hover:opacity-100 active:opacity-100"
                  />
                </div>
              {/if} --}
            </span>
            {#if slot_assigned?(:label_end) && @focus_label_first}
              <#slot {@label_end} />
            {/if}
          </Label>
        </div>
      {/if}
      {#if @caption}
        <div class="text-sm text-opacity-50 help text-base-content">
          {@caption}
        </div>
      {/if}
      <#slot {@caption_end} />
      <div class="grid grid-cols-1 gap-2">
        <div class="flex flex-row gap-2">
          <div class={"control w-full", @wrapper_class}>
            <#slot {@left} />
            <TextArea
              class={
                "textarea",
                "textarea-bordered",
                "h-40",
                "w-full",
                "text-base",
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
      {#if slot_assigned?(:label_end) && !@focus_label_first}
        <div class="absolute top-0 right-0 h-fit">
          <#slot {@label_end} />
        </div>
      {/if}
    </Field>
    """
  end
end
