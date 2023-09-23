defmodule BanchanWeb.Components.Form.Select do
  @moduledoc """
  Banchan-specific TextInput.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Select}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop wrapper_class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop focus_label_first, :boolean, default: true
  prop icon, :string
  prop caption, :string
  prop info, :string
  prop prompt, :string
  prop selected, :any
  prop options, :any, default: []
  prop form, :form, from_context: {Form, :form}

  slot label_end
  slot left
  slot right
  slot caption_end

  def render(assigns) do
    ~F"""
    <Field class={"relative grid grid-cols-1 gap-2 field", @wrapper_class} name={@name}>
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
          </Label>
          {#if slot_assigned?(:label_end) && @focus_label_first}
            <#slot {@label_end} />
          {/if}
        </div>
      {/if}
      {#if @caption}
        <div class="text-sm text-opacity-50 help text-base-content">
          {@caption}
        </div>
      {/if}
      <#slot {@caption_end} />
      <div class="grid grid-cols-1 gap-2">
        <div class="flex flex-row w-full gap-4 control">
          <#slot {@left} />
          {#if @icon}
            <Icon name={"#{@icon}"} size="4" />
          {/if}
          <Select
            class={
              "w-full bg-p-0 select select-bordered focus:ring focus:ring-primary",
              @class,
              "select-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
            }
            prompt={@prompt}
            selected={@selected}
            opts={@opts}
            options={@options}
          />
          <#slot {@right} />
        </div>
        <ErrorTag class="help text-error" />
        {#if slot_assigned?(:label_end) && !@focus_label_first}
          <div class="absolute top-0 right-0 h-fit">
            <#slot {@label_end} />
          </div>
        {/if}
      </div>
    </Field>
    """
  end
end
