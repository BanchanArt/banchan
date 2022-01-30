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
    description: "Kitteh-related stuff",
    summary: """
    ### These are all private commissions, meaning: **non-commercial**

    You're only paying for my service to create the work not copyrights or licensing of the work itself!

    #### I will draw

    * Humans/humanoids
    * anthros+furries/creatures/monsters/animals
    * mecha/robots/vehicles
    * environments/any type of background

    #### I will not draw

    * NSFW
    * Fanart
    """
  })

Banchan.Offerings.new_offering(studio, %{
  type: "illustration",
  index: 0,
  name: "Illustration",
  description: "A detailed illustration with full rendering and background.",
  open: true,
  terms: "You break it, you **buy** it.",
  options: [
    %{
      name: "option1",
      description: "Option 1",
      price: Money.new(500, :USD)
    },
    %{
      name: "option2",
      description: "Option 2",
      price: Money.new(4500, :USD)
    }
  ]
})

Banchan.Offerings.new_offering(studio, %{
  type: "chibi",
  index: 1,
  name: "Chibi",
  description: "Big eyes, small mouth, tiny body, big heart.",
  open: true,
  base_price: Money.new(5000, :USD),
  options: [
    %{
      name: "Extra Character",
      description: "Add an extra characte to the commission.",
      price: Money.new(2500, :USD)
    }
  ]
})
