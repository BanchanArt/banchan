defmodule BanchanWeb.Components.Commissions.Summary do
  @moduledoc """
  Summary card for the Commissions Page sidebar
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Card

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        Summary
      </:header>

      <ul class="divide-y">
        <li class="offering container p-4">
          <div class="float-right">
            $150.00 <i class="fas fa-times-circle" />
          </div>
          <div class="offering-name">
            <span class="offering-amount">2x</span> Character
          </div>
          <div>Full lineart for one or more characters.</div>
        </li>
        <li class="offering container box-border p-4">
          <div class="float-right">
            $50.00 <i class="fas fa-times-circle" />
          </div>
          <div class="offering-name">
            Full Color
          </div>
          <div>Add full, shaded color to the illustration.</div>
        </li>
        <li class="offering container box-border p-4">
          <div class="float-right">
            $50.00 <i class="fas fa-times-circle" />
          </div>
          <div class="offering-name">
            Color Background
          </div>
          <div>Add a full, color background.</div>
        </li>
      </ul>
      <hr>
      <div class="container">
        <p class="p-4">Estimate: <span class="float-right">$250.00</span></p>
      </div>

      <:footer>
        <a class="text-center rounded-full py-1 px-5 bg-amber-200 text-black m-1" href="#">Add Offering</a>
      </:footer>
    </Card>
    """
  end
end
