defmodule BanchanWeb.Components.ButtonPlayground do
  @moduledoc """
  Catalogue playground for the `<Button>` component.
  """

  use Surface.Catalogue.Playground,
    subject: BanchanWeb.Components.Button,
    height: "100px"

    @props []

    @slots [
      default: "My button"
    ]
end
