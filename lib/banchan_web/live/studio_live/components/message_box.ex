defmodule BanchanWeb.StudioLive.Components.Commissions.MessageBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{Submit, TextArea}

  prop new_message, :event, required: true
  prop changeset, :any

  def render(assigns) do
    ~F"""
    <div class="message-box">
      <Form for={:message} submit={@new_message}>
        <TextArea name={:message} label="Send a Message" opts={required: true} />
        <Submit changeset={@changeset} label="Reply" />
      </Form>
    </div>
    """
  end
end
