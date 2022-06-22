defmodule Banchan.Utils do
  @moduledoc """
  Collection of miscellaneous utilities that don't quite fit anywhere else.
  """

  def moneyfy(amount, currency) do
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
