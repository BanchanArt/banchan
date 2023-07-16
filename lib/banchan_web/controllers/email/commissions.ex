defmodule BanchanWeb.Email.Commissions do
  @moduledoc """
  Rendering emails related to the Commissions context.
  """
  use BanchanWeb, :html

  alias Banchan.Commissions

  alias BanchanWeb.Components.Markdown

  def render("receipt.html", assigns) do
    estimate = Commissions.line_item_estimate(assigns.invoice.line_items)

    default_currency = estimate.currency

    tipped = assigns.tipped || Money.new(0, default_currency)

    ~F"""
    <h2>Banchan Art Payment Receipt</h2>
    <h3>{@commission.title}</h3>
    <p><Markdown content={@invoice.event.text} /></p>
    <table>
      <tr>
        <th>Item</th>
        <th>Description</th>
        <th>Amount</th>
      </tr>
      {#for item <- @invoice.line_items}
        <tr>
          <td>{item.name}</td>
          <td>{item.description}</td>
          <td>{Money.to_string(item.amount)}</td>
        </tr>
      {/for}
      <tr>
        <td colspan="2">Total Invoiced</td>
        <td>{Money.to_string(estimate)}</td>
      </tr>
      <tr>
        <td colspan="2">Additional Tip</td>
        <td>{Money.to_string(tipped)}</td>
      </tr>
    </table>
    """
  end

  def render("receipt.text", assigns) do
    estimate = Commissions.line_item_estimate(assigns.invoice.line_items)

    default_currency = estimate.currency

    tipped = assigns.tipped || Money.new(0, default_currency)

    """
    Banchan Art Payment Receipt
    ===========================

    Title: #{assigns.commission.title}

    Invoice Details:
    #{assigns.invoice.event.text}

    Line Items:

    #{assigns.invoice.line_items |> Enum.map_join("\n", fn item -> """
      * #{item.name} - #{Money.to_string(item.amount)}
        #{item.description}
      """ end)}
    Total Invoiced: #{Money.to_string(estimate)}
    Additional Tip: #{Money.to_string(tipped)}
    """
  end
end
