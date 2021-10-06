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

      <ul class="offering-list">
        <li class="block offering">
          <div class="tags has-addons">
            <span class="tag is-medium">
              2 Characters
            </span>
            <span class="tag is-medium is-success">
              $150.00
              <button class="delete is-small" />
            </span>
          </div>
        </li>
        <li class="block offering">
          <div class="tags has-addons">
            <span class="tag is-medium">
              Full Color
            </span>
            <span class="tag is-medium is-success">
              $50.00
              <button class="delete is-small" />
            </span>
          </div>
        </li>
        <li class="block offering">
          <div class="tags has-addons">
            <span class="tag is-medium">
              Color Background
            </span>
            <span class="tag is-medium is-success">
              $50.00
              <button class="delete is-small" />
            </span>
          </div>
        </li>
      </ul>
      <hr>
      <p>Estimate: <span class="tag is-medium is-success">$250.00</span></p>

      <:footer>
        <a class="card-footer-item button is-primary" href="#">Add Offering</a>
      </:footer>
    </Card>
    """
  end
end
