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
  prop icon, :string
  prop info, :string
  prop selected, :any
  prop options, :any, default: []
  prop form, :form, from_context: {Form, :form}

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      {#if @show_label}
        <Label class="label">
          <span class="flex flex-row items-center gap-1 label-text">
            {@label || Phoenix.Naming.humanize(@name)}
            {#if @info}
              <div class="tooltip tooltip-right" data-tip={@info}>
                <Icon name="info" size="4" label="tooltip tooltip-right" />
              </div>
            {/if}
          </span>
        </Label>
      {/if}
      <div class="flex flex-col">
        <div class="flex flex-row gap-2">
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
        </div>
        <ErrorTag class="text-error" />
      </div>
    </Field>
    """
  end
end
