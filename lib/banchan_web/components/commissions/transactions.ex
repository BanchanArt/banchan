defmodule BanchanWeb.Components.Commissions.Transactions do
  @moduledoc """
  Displays transactions for a commission.
  """
  use BanchanWeb, :live_component

  def render(assigns) do
    ~F"""
    <div class="card">
      <header class="card-header">
        <p class="card-header-title">Transactions</p>
      </header>
      <div class="card-content">
        <p><i class="fas fa-donate" /> <span class="tag is-medium is-success">$100.25</span></p>
      </div>
      <footer class="card-footer">
        <a class="card-footer-item button is-primary" href="#">Request Payment</a>
        <a class="card-footer-item button is-warning" href="#">Refund</a>
      </footer>
    </div>
    """
  end
end
