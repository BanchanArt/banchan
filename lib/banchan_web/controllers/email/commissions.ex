defmodule BanchanWeb.Email.Commissions do
  @moduledoc """
  Rendering emails related to the Commissions context.
  """
  use BanchanWeb, :html

  alias Banchan.Commissions
  alias Banchan.Payments

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
          <td>{Payments.print_money(item.amount)}</td>
        </tr>
      {/for}
      <tr>
        <td colspan="2">Total Invoiced</td>
        <td>{Payments.print_money(estimate)}</td>
      </tr>
      <tr>
        <td colspan="2">Additional Tip</td>
        <td>{Payments.print_money(tipped)}</td>
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
      * #{item.name} - #{Payments.print_money(item.amount)}
        #{item.description}
      """ end)}
    Total Invoiced: #{Payments.print_money(estimate)}
    Additional Tip: #{Payments.print_money(tipped)}
    """
  end
end
