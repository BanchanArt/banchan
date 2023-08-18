defmodule BanchanWeb.Components.Form.NumberInput do
  @moduledoc """
  Banchan-specific NumberInput.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, NumberInput}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop info, :string
  prop icon, :string
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
      {/if}
      <div class="flex flex-col">
        <div class={
          "flex flex-row w-full gap-2 control input input-bordered focus-within:ring ring-primary",
          "input-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
        }>
          {#if @icon}
            <Icon name={"#{@icon}"} size="4" />
          {/if}
          <NumberInput
            class={
              "w-full bg-transparent p-0 ring-0 outline-none border-none focus:ring-0",
              @class
            }
            opts={[{:phx_debounce, "200"} | @opts]}
          />
        </div>
        <ErrorTag class="help text-error" />
      </div>
    </Field>
    """
  end
end
