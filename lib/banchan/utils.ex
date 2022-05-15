defmodule Banchan.Utils do
  @moduledoc """
  Collection of miscellaneous utilities that don't quite fit anywhere else.
  """

  def moneyfy(amount) do
    # TODO: In the future, we can replace this :USD with a param and the DB will be fine.
    case Money.parse(amount, :USD) do
      {:ok, money} ->
        money

      :error ->
        # NB(zkat): the assumption here is that the value will be validated by
        # Ecto changeset stuff.
        amount
    end
  end
end
