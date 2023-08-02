defmodule BanchanWeb.Components.OfferingCardPlayground do
  @moduledoc """
  Catalogue playground for the `<OfferingCard>` component.
  """

  use Surface.Catalogue.Playground,
    subject: BanchanWeb.Components.OfferingCard,
    height: "400px",
    container: {:div, "data-theme": "light"}

  @props []
end
