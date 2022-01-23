# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Banchan.Repo.insert!(%Banchan.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{:ok, user} =
  Banchan.Accounts.register_admin(%{
    handle: "zkat",
    email: "kat@dwg.dev",
    password: "foobarbazquux",
    password_confirmation: "foobarbazquux"
  })

{:ok, studio} =
  Banchan.Studios.new_studio(%Banchan.Studios.Studio{artists: [user]}, %{
    handle: "kitteh-studio",
    name: "Kitteh Studio",
    description: "Kitteh-related stuff"
  })

Banchan.Offerings.new_offering(studio, %{
  type: "illustration",
  index: 0,
  name: "Illustration",
  description: "A detailed illustration with full rendering and background.",
  open: true,
  terms: "You break it, you **buy** it."
})
