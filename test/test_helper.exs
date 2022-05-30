ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Banchan.Repo, {:shared, self()})

# This is defined in seeds.exs so I don't think it's necessary here.
# Mox.defmock(Banchan.StripeAPI.Mock, for: Banchan.StripeAPI.Base)
