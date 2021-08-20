# Banchan.Art

[View the Wiki here.](https://github.com/digitalworkersguild/banchan/wiki)
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

For additional details on working with this repo, [view the wiki article here.](https://github.com/digitalworkersguild/banchan/wiki/Getting-Started#useful-commands-reference)
