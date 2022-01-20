# Contributing

Patches welcome! Banchan is meant to be an open project that accepts
improvements from the community, and we strive to make that process as easy as
possible.

If you're interested in working on Banchan in a code capacity, you can get
started in a few easy steps:

1. Submit a PR adding your name to [our CLA](https://github.com/digitalworkersguild/banchan/blob/main/CLA.md#signatures).
2. [Set up the repo](#setup).
3. Find a [good first issue](https://github.com/digitalworkersguild/banchan/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) or one that's [help wanted](https://github.com/digitalworkersguild/banchan/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22). You can also reach out to use [on the DWG Discord](https://discord.gg/sU2wSxbT8b).
4. Happy hacking!

## App Setup

Banchan is an Elixir/Phoenix application meant to be hosted on cloud
providers, but most functionality can be run locally as well.

Requirements:
- [Elixir 1.6+](https://elixir-lang.org/install.html)
- Erlang 20+ (Typically auto-installs with Elixir)
- [Phoenix](https://hexdocs.pm/phoenix/installation.html)
- [Postgresql](https://wiki.postgresql.org/wiki/Detailed_installation_guides)

Note: If postgresql installed via homebrew, make sure to run `/usr/local/opt/postgres/bin/createuser -s postgres`.

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Set up your env vars file. Create `.env` (*NIX) or `.env.ps1` (Powershell)
  - Add commands for your environment variables there
  - This gets loaded automatically
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- To make sure everything is good, run `mix quality`
- Start Phoenix endpoint with `mix phx.server`
- Stop by typing Ctrl+C twice.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

For additional details on working with this repo, [view the wiki article here.](https://github.com/digitalworkersguild/banchan/wiki/Getting-Started#useful-commands-reference)
