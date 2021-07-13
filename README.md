# Banchan
## Setup

Requirements:
- [Elixir 1.6+](https://elixir-lang.org/install.html)
- Erland 20+ (Typically auto-installs with Elixer)
- [Phoenix](https://hexdocs.pm/phoenix/installation.html)
- [Postgresql](https://wiki.postgresql.org/wiki/Detailed_installation_guides)

Note: If postgresql installed via homebrew, make sure to run `/usr/local/opt/postgres/bin/createuser -s postgres`.

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
