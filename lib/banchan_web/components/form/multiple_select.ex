defmodule BanchanWeb.Components.Form.MultipleSelect do
  @moduledoc """
  Banchan-specific TextInput.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, MultipleSelect}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop focus_label_first, :boolean, default: true
  prop icon, :string
  prop info, :string
  prop caption, :string
  prop selected, :any
  prop options, :any, default: []
  prop form, :form, from_context: {Form, :form}

  slot caption_end
  slot left
  slot right
  slot label_end

  def render(assigns) do
    ~F"""
    <Field class="relative grid grid-cols-1 gap-1 field" name={@name}>
      {#if @show_label}
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
            {/if}
            --}
          </span>
        </Label>
        {#if slot_assigned?(:label_end) && @focus_label_first}
          <#slot {@label_end} />
        {/if}
      {/if}
      {#if @caption}
        <div class="text-sm text-opacity-50 help text-base-content">
          {@caption}
        </div>
      {/if}
      <#slot {@caption_end} />
      <div class="grid grid-cols-1 gap-2">
        <div class="flex flex-row gap-2">
          <#slot {@left} />
          {#if @icon}
            <Icon name={"#{@icon}"} size="4" />
          {/if}
          <div class="w-full control">
            <MultipleSelect
              class={
                "textarea",
                "textarea-bordered",
                "w-full",
                @class,
                "textarea-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
              }
              selected={@selected}
              opts={@opts}
              options={@options}
            />
          </div>
          <#slot {@right} />
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
