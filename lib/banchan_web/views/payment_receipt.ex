defmodule BanchanWeb.PaymentReceiptView do
  use BanchanWeb, :view

  alias Banchan.Commissions

  def render("receipt.html", assigns) do
    estimate = Commissions.line_item_estimate(assigns.commission.line_items)

    deposited =
      if is_nil(assigns.deposited) || Enum.empty?(assigns.deposited) do
        [Money.new(0, assigns.default_currency)]
      else
        assigns.deposited |> Map.values()
      end

    tipped =
      if is_nil(assigns.tipped) || Enum.empty?(assigns.tipped) do
        [Money.new(0, assigns.default_currency)]
      else
        assigns.tipped |> Map.values()
      end

    remaining =
      if is_nil(assigns.deposited) || Enum.empty?(assigns.deposited) do
        Map.values(estimate)
      else
        assigns.deposited
        |> Enum.map(fn {currency, amount} ->
          Money.subtract(Map.get(estimate, currency, Money.new(0, currency)), amount)
        end)
      end

    estimate = Map.values(estimate)

    ~F"""
    <h2>Banchan Art Payment Receipt</h2>
    <h3>{@commission.title}</h3>
    <p>{@invoice.event.text}</p>
    <table>
      <tr>
        <th>Item</th>
        <th>Description</th>
        <th>Amount</th>
      </tr>
      {#for item <- @commission.line_items}
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
        <td>
          {#for val <- deposited}
            {Money.to_string(val)}
          {/for}
        </td>
      </tr>
      <tr>
        <td colspan="2">Quote</td>
        <td>
          {#for val <- estimate}
            {Money.to_string(val)}
          {/for}
        </td>
      </tr>
      <tr>
        <td colspan="2">Balance</td>
        <td>
          {#for val <- remaining}
            {Money.to_string(val)}
          {/for}
        </td>
      </tr>
      <tr>
        <td colspan="2">Additional Tips</td>
        <td>
          {#for val <- tipped}
            {Money.to_string(val)}
          {/for}
        </td>
      </tr>
    </table>
    """
  end
end
