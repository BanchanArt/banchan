defmodule BanchanWeb.Components.Form.LitSelectPlayground do
  @moduledoc """
  Catalogue playground for the `<LitSelect>` component.
  """

  use Surface.Catalogue.Playground,
    subject: BanchanWeb.Components.Form.LitSelect,
    height: "400px",
    container: {:div, "data-theme": "light"}

  @props [id: "lit-select-playground", form: to_form(%{})]
end
