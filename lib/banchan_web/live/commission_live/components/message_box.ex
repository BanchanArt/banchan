defmodule BanchanWeb.Components.Commissions.MessageBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextArea}
  alias Surface.Components.Form.Input.InputContext

  prop new_message, :event, required: true

  def render(assigns) do
    ~F"""
    <div class="message-box">
      <Form for={:message} submit={@new_message}>
        <Field class="field" name={:message}>
          <Label class="label">Send a Message</Label>
          <div class="control">
            <InputContext :let={form: form, field: field}>
              <TextArea
                class={"textarea", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                opts={required: true}
              />
            </InputContext>
          </div>
          <ErrorTag class="help is-danger" />
        </Field>
        <div class="field">
          <div class="control">
            <Submit class="btn-base btn-amber" label="Reply" />
          </div>
        </div>
      </Form>
    </div>
    """
  end
end
