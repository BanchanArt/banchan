ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Banchan.Repo, :manual)
Mox.defmock(Banchan.StripeAPI.Mock, for: Banchan.StripeAPI.Base)
