defmodule Banchan.Utils do
  @moduledoc """
  Collection of miscellaneous utilities that don't quite fit anywhere else.
  """

  def moneyfy(amount, currency) when is_binary(currency) do
    currency = currency |> String.upcase() |> String.to_existing_atom()
    moneyfy(amount, currency)
  rescue
    ArgumentError ->
      amount
  end

  def moneyfy(amount, currency) when is_atom(currency) do
    case Money.parse(amount, currency) do
      {:ok, money} ->
        money

      :error ->
        # NB(zkat): the assumption here is that the value will be validated by
        # Ecto changeset stuff.
        amount
    end
  end
end
