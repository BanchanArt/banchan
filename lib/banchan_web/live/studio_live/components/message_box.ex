defmodule BanchanWeb.StudioLive.Components.Commissions.MessageBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  alias BanchanWeb.Components.Form.TextArea

  prop new_message, :event, required: true

  def render(assigns) do
    ~F"""
    <div class="message-box">
      <Form for={:message} submit={@new_message}>
        <TextArea name={:message} label="Send a Message" opts={required: true} />
        <div class="field">
          <div class="control">
            <Submit class="btn btn-secondary text-center rounded-full py-1 px-5 m-1" label="Reply" />
          </div>
        </div>
      </Form>
    </div>
    """
  end
end
