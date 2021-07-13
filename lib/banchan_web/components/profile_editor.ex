defmodule BanchanWeb.Components.ProfileEditor do
  @moduledoc """
  Renders a form that edits a changeset.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextInput}

  prop change, :event, required: true
  prop submit, :event, required: true
  prop for, :changeset, required: true
  prop fields, :list, required: true

  @impl true
  def render(assigns) do
    ~F"""
    <Form for={@for} change={@change} submit={@submit} opts={autocomplete: "off"}>
      {#for field <- @fields}
        <Field name={field}>
          <Label />
          <TextInput />
          <ErrorTag />
        </Field>
      {/for}
      <Submit label="Save" opts={disabled: Enum.empty?(@for.changes) || !@for.valid?} />
    </Form>
    """
  end
end
