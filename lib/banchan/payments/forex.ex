defmodule Banchan.Payments.Forex do
  @moduledoc """
  Schema and Agent (don't look at me like that) for foreign exchange conversions.
  """
  use Ecto.Schema
  import Ecto.Changeset
  use Agent

  alias Banchan.Payments
  alias Banchan.Studios

  schema "foreign_exchange_rates" do
    field(:from, Ecto.Enum, values: Studios.Common.supported_currencies())
    field(:to, Ecto.Enum, values: Studios.Common.supported_currencies())
    field(:rate, :float)
    timestamps()
  end

  def changeset(forex, attrs) do
    forex
    |> cast(attrs, [:from, :to, :rate])
    |> validate_required([:from, :to, :rate])
  end

  def start_link(opts) do
    {base_currency, opts} = Keyword.pop(opts, :base_currency, Payments.platform_currency())

    Agent.start_link(
      fn -> %{base_currency => Payments.load_exchange_rates(base_currency)} end,
      opts
    )
  end

  def get_forex_rate(agent, from, to) do
    Agent.get_and_update(agent, fn rates ->
      if from == to do
        {1.0, rates}
      else
        # First, we check if we have the rates for the `from` currency already
        # loaded. If not, we grab them from the database.
        from_rates = Map.get(rates, from, %{})
        forex = Map.get(from_rates, to)

        if is_nil(forex) || forex_old?(forex) do
          # Try to load from the DB again, in case we already have a new rate.
          db_rates = Payments.load_exchange_rates(from)
          db_forex = Map.get(db_rates, to)

          # If we still don't have anything in the DB, or the DB stuff is also
          # out of date, we go ahead and update.
          new_rates =
            if is_nil(db_rates) ||
                 is_nil(forex) ||
                 (db_forex && forex_old?(db_forex)) do
              latest_rates(from, db_rates, from_rates)
            else
              db_rates
            end

          {Map.get(new_rates, to, %__MODULE__{}).rate, Map.put(rates, from, new_rates)}
        else
          # Otherwise, we still need to update the Agent state in case our
          # rates were loaded from the db.
          {forex.rate, Map.put(rates, from, from_rates)}
        end
      end
    end)
  end

  def forget_rates(agent, from) do
    Agent.update(agent, fn rates -> Map.delete(rates, from) end)
  end

  defp latest_rates(from, db_rates, agent_rates) do
    case Payments.update_exchange_rates(from) do
      {:ok, updated} ->
        updated

      {:error, _} ->
        # On error, we just use whatever rates we can get, even if
        # they're out of date.
        if Enum.empty?(db_rates) do
          agent_rates
        else
          db_rates
        end
    end
  end

  defp forex_old?(%__MODULE__{updated_at: updated_at}) do
    Timex.before?(
      Timex.to_datetime(updated_at),
      Timex.shift(Timex.now(), hours: -12)
    )
  end
end
