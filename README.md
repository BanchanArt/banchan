# Banchan
## Setup

Requirements:
- [Elixir 1.6+](https://elixir-lang.org/install.html)
- Erlang 20+ (Typically auto-installs with Elixir)
- [Phoenix](https://hexdocs.pm/phoenix/installation.html)
- [Postgresql](https://wiki.postgresql.org/wiki/Detailed_installation_guides)

Note: If postgresql installed via homebrew, make sure to run `/usr/local/opt/postgres/bin/createuser -s postgres`.

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- To make sure everything is good, run `mix quality`
- Start Phoenix endpoint with `mix phx.server`
- Stop by typing Ctrl+C twice.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Banchan Art Notes

On Dev mode:
- `/admin/sent-emails` to view confirmation emails, password resets, etc since dev mode does not send real emails

Other:
- `assets/css/bulma.scss` for theme customization (overrides Bulma defaults)
- `lib/banchan/accounts/user.ex` for user account setting defaults

### Adding static files

- Static files go in `assets/static/`.
- Images go in `assets/static/images/`.

Compilation Steps for static files
- `npm run deploy --prefix ./assets`
- `mix phx.digest`

Location of images after compiling for live site: `/priv/static/images/`.
Example of how to link images from that location: `<img src={Routes.static_path(Endpoint, "/images/shop_card_default.png")} />`

## Learn more about Elixir

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
