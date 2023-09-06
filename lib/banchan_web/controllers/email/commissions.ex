defmodule BanchanWeb.Email.Commissions do
  @moduledoc """
  Rendering emails related to the Commissions context.
  """
  use BanchanWeb, :html

  alias Banchan.Commissions
  alias Banchan.Payments

  alias BanchanWeb.Components.RichText

  def render("receipt.html", assigns) do
    estimate = Commissions.line_item_estimate(assigns.invoice.line_items)

    default_currency = estimate.currency

    tipped = assigns.tipped || Money.new(0, default_currency)

    ~F"""
    <h2>Banchan Art Payment Receipt</h2>
    <h3>{@commission.title}</h3>
    <p><RichText content={@invoice.event.text} /></p>
    <table>
      <tr>
        <th>Item</th>
        <th>Description</th>
        <th>Amount</th>
      </tr>
      {#for item <- @invoice.line_items}
        <tr>
          <td>{item.name}{#if item.multiple && item.count > 1}
              x{item.count}{/if}</td>
          <td>{item.description}</td>
          <td>{Payments.print_money(Money.multiply(item.amount, item.count))}</td>
        </tr>
      {/for}
      <tr>
        <td colspan="2">Subtotal</td>
        <td>{Payments.print_money(estimate)}</td>
      </tr>
      <tr>
        <td colspan="2">Additional Tip</td>
        <td>{Payments.print_money(tipped)}</td>
      </tr>
      <tr>
        <td colspan="2">Tax/VAT</td>
        <td>{Payments.print_money(@taxes)}</td>
      </tr>
      <tr>
        <td colspan="2">Total</td>
        <td>{Payments.print_money(@charged)}</td>
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
      * #{item.name}#{if item.multiple && item.count > 1 do
        " x#{item.count}"
      else
        ""
      end} - #{Payments.print_money(Money.multiply(item.amount, item.count))}
        #{item.description}
      """ end)}
    Subtotal: #{Payments.print_money(estimate)}
    Additional Tip: #{Payments.print_money(tipped)}
    Tax/VAT: #{Payments.print_money(assigns.taxes)}
    ----------------------------
    Total: #{Payments.print_money(assigns.charged)}
    """
  end
end
