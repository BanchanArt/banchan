defmodule BanchanWeb.Components.Form.Select do
  @moduledoc """
  Banchan-specific TextInput.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.{ErrorTag, Field, Label, Select}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop icon, :string
  prop options, :any, default: []

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
          <Select
            class={
              "select",
              "select-primary",
              "select-bordered",
              "w-full",
              @class,
              "has-icon-left": @icon,
              "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
            }
            opts={@opts}
            options={@options}
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
