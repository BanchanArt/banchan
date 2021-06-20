# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Bespoke.Repo.insert!(%Bespoke.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
{:ok, user} =
  Bespoke.Users.User.create(%{
    email: "test@example.com",
    display_name: "Test User",
    password: "foobarbaz",
    password_confirmation: "foobarbaz"
  })

PowEmailConfirmation.Ecto.Context.confirm_email(user, %{}, otp_app: :bespoke)
