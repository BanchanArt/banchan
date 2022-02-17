defmodule BanchanWeb.StudioLive.Components.Commissions.Status do
  @moduledoc """
  Status box with dropdown, for Commissions page.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions.Common

  alias Surface.Components.Form
  alias Surface.Components.Form.Select

  alias BanchanWeb.Components.Card

  prop change, :event, required: true
  prop editable, :boolean, default: false
  prop commission, :any, required: true

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        Status
      </:header>

      {#if @editable}
        <Form for={:status} change={@change}>
          <div class="select">
            <Select
              selected={@commission.status}
              options={[
                Submitted: :submitted,
                Accepted: :accepted,
                Paused: :paused,
                "In Progress": :in_progress,
                "Waiting for Client": :waiting,
                Closed: :closed
              ]}
            />
          </div>
        </Form>
      {#else}
        {Common.humanize_status(@commission.status)}
      {/if}
    </Card>
    """
  end
end
