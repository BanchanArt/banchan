defmodule BanchanWeb.Components.Form.EmailInput do
  @moduledoc """
  Canonical email input for Banchan
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Icon

  alias Surface.Components.Form
  alias Surface.Components.Form.{EmailInput, ErrorTag, Field, Label}

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop wrapper_class, :css_class
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
                <Icon name="info" size="4" label="tooltip tooltip-right" />
              </div>
            {/if}
          </span>
        </Label>
      {/if}
      <div class="flex flex-col">
        <div class={
          "flex flex-row gap-2 w-full control input input-bordered focus-within:ring ring-primary",
          @wrapper_class
        }>
          {#if @icon}
            <Icon name={"#{@icon}"} size="4" />
          {/if}
          <EmailInput
            class={
              "w-full bg-transparent ring-0 outline-none border-none focus:ring-0",
              @class,
              "input-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
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
