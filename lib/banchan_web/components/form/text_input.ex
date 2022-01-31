defmodule BanchanWeb.Components.Form.TextInput do
  @moduledoc """
  Banchan-specific TextInput.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextInput}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop icon, :string

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      {#if @show_label}
        {#if @label}
          <Label class="label">
            {@label}
          </Label>
        {#else}
          <Label class="label" />
        {/if}
      {/if}
      <div class="control">
        <InputContext :let={form: form, field: field}>
          <TextInput
            class={
              "input",
              "input-primary",
              "input-bordered",
              "input-sm",
              @class,
              "has-icon-left": @icon,
              "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
            }
            opts={@opts}
          />
        </InputContext>
        {#if @icon}
          <span class="icon is-small is-left">
            <i class={"fas", "fa-#{@icon}"} />
          </span>
        {/if}
      </div>
      <ErrorTag class="help is-danger" />
    </Field>
    """
  end
end
