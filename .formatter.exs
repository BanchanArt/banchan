[
  import_deps: [:ecto, :phoenix, :surface],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs,sface}"],
  subdirectories: ["priv/*/migrations"],
  plugins: [Surface.Formatter.Plugin]
]
