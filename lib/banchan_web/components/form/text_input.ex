defmodule BanchanWeb.Components.Form.TextInput do
  @moduledoc """
  Banchan-specific TextInput.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, TextInput}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop wrapper_class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop info, :string
  prop caption, :string
  prop icon, :string
  prop form, :form, from_context: {Form, :form}

  slot label_end
  slot left
  slot right
  slot caption_end

  def render(assigns) do
    ~F"""
    <Field class={"relative grid grid-cols-1 gap-2 field", @wrapper_class} name={@name}>
      {#if @show_label}
        <div class={"flex flex-row items-center gap-4", "justify-between": slot_assigned?(:label_end)}>
          <Label class="p-0 label">
            <span class="flex flex-row items-center gap-1 text-sm label-text">
              {@label || Phoenix.Naming.humanize(@name)}
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
            </span>
          </Label>
        </div>
      {/if}
      <div class="grid grid-cols-1 gap-2">
        <div class={
          "flex flex-row w-full gap-4 control input input-bordered focus-within:ring ring-primary",
          "input-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
        }>
          {#if slot_assigned?(:left)}
            <#slot {@left} />
          {/if}
          {#if @icon}
            <Icon name={"#{@icon}"} size="4" />
          {/if}
          <TextInput
            class={
              "w-full bg-transparent p-0 ring-0 outline-none border-none focus:ring-0",
              @class
            }
            opts={[{:phx_debounce, "200"} | @opts]}
          />
          {#if slot_assigned?(:right)}
            <#slot {@right} />
          {/if}
        </div>
        <ErrorTag class="help text-error" />
        {#if @caption}
          <div class="text-sm text-opacity-50 help text-base-content">
            {@caption}
          </div>
        {/if}
        {#if slot_assigned?(:caption_end)}
          <#slot {@caption_end} />
        {/if}
      </div>
      {#if slot_assigned?(:label_end)}
        <div class="absolute top-0 right-0 h-fit">
          <#slot {@label_end} />
        </div>
      {/if}
    </Field>
    """
  end
end
