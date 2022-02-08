Common issues and how to fix them
=================================

(UndefinedFunctionError) function :crypto.hmac/3 is undefined or private
------------------------------------------------------------------------

This is happening because Erlang OTP 24 no longer supports :crypto.hmac/3. Update your dependencies by calling `mix deps.update --all`

Source: https://elixirforum.com/t/undefinedfunctionerror-function-crypto-hmac-3-is-undefined-or-private/40060/8

if your local database gets absolutely borked
---------------------------------------------

run `mix ecto.reset`
