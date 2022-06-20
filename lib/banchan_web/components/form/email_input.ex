defmodule BanchanWeb.Components.Form.EmailInput do
  @moduledoc """
  Canonical email input for Banchan
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{EmailInput, ErrorTag, Field, Label}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop wrapper_class, :css_class
  prop class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop info, :string
  prop icon, :string

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
          {#if @icon}
            <span class="icon text-2xl my-auto">
              <i class={"fas fa-#{@icon}"} />
            </span>
          {/if}
          <div class={"w-full control", @wrapper_class}>
            <InputContext :let={form: form, field: field}>
              <EmailInput
                class={
                  "input",
                  "input-bordered",
                  "w-full",
                  @class,
                  "input-error": !Enum.empty?(Keyword.get_values(form.errors, field))
                }
                opts={@opts}
              />
            </InputContext>
          </div>
        </div>
        <ErrorTag class="help text-error" />
      </div>
    </Field>
    """
  end
end
