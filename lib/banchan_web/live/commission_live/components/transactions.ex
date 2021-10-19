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
        <a class="text-center rounded-full py-1 px-5 bg-amber-200 text-black m-1" href="#">Request Payment</a>
        <a class="text-center rounded-full py-1 px-5 bg-red-200 text-black m-1" href="#">Refund</a>
      </:footer>
    </Card>
    """
  end
end
