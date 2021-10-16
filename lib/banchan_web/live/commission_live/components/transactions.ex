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

      <p><i class="fas fa-donate" /> $100.25</p>

      <:footer>
        <a class="button primary" href="#">Request Payment</a>
        <a class="button warning" href="#">Refund</a>
      </:footer>
    </Card>
    """
  end
end
