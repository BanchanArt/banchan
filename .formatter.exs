[
  import_deps: [:ecto, :ecto_sql, :phoenix, :surface],
  subdirectories: ["priv/*/migrations"],
  plugins: [Surface.Formatter.Plugin],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs,sface}"]
]
