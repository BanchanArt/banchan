defmodule BanchanWeb.Components.Commissions.Status do
  @moduledoc """
  Status box with dropdown, for Commissions page.
  """
  use BanchanWeb, :component

  alias Surface.Components.Form
  alias Surface.Components.Form.Select

  alias BanchanWeb.Components.Card

  prop change, :event, required: true
  prop commission, :any, required: true

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        <p class="card-header-title">Status</p>
      </:header>

      <Form for={:status} change={@change}>
        <div class="select">
          <Select
            selected={@commission.status}
            options={[
              Pending: :pending,
              Accepted: :accepted,
              Paused: :paused,
              "In Progress": :in_progress,
              "Waiting for Customer": :waiting,
              Closed: :closed
            ]}
          />
        </div>
      </Form>
    </Card>
    """
  end
end
