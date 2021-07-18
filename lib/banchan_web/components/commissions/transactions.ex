defmodule BanchanWeb.Components.Commissions.Transactions do
  @moduledoc """
  Displays transactions for a commission.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Card

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        Transactions
      </:header>

      <p><i class="fas fa-donate" /> <span class="tag is-medium is-success">$100.25</span></p>

      <:footer>
        <a class="card-footer-item button is-primary" href="#">Request Payment</a>
        <a class="card-footer-item button is-warning" href="#">Refund</a>
      </:footer>
    </Card>
    """
  end
end
