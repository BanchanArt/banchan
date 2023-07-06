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

    deposited = assigns.deposited || Money.new(0, default_currency)

    tipped = assigns.tipped || Money.new(0, default_currency)

    remaining = Money.subtract(estimate, deposited)

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
        <td colspan="2">Invoice Charged</td>
        <td>
          {Money.to_string(@invoice.total_charged)}
        </td>
      </tr>
      <tr>
        <td colspan="2">Paid to Date</td>
        <td>{Money.to_string(deposited)}</td>
      </tr>
      <tr>
        <td colspan="2">Quote</td>
        <td>{Money.to_string(estimate)}</td>
      </tr>
      <tr>
        <td colspan="2">Balance</td>
        <td>{Money.to_string(remaining)}</td>
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

    deposited = assigns.deposited || Money.new(0, default_currency)

    tipped = assigns.tipped || Money.new(0, default_currency)

    remaining = Money.subtract(estimate, deposited)

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
    Invoice Charged: #{Money.to_string(assigns.invoice.total_charged)}
    Paid to Date: #{Money.to_string(deposited)}
    Quote: #{Money.to_string(estimate)}
    Balance: #{Money.to_string(remaining)}
    Additional Tip: #{Money.to_string(tipped)}
    """
  end
end
