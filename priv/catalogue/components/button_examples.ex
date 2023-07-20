defmodule BanchanWeb.Components.ButtonExamples do
  @moduledoc """
  Examples for the `<Button>` component
  """

  use Surface.Catalogue.Examples,
    subject: BanchanWeb.Components.Button,
    height: "100px"

  alias BanchanWeb.Components.Button

  @example true
  @doc "An example for the `primary` property"
  def primary(assigns) do
    ~F"""
    <Button>Primary true</Button>
    <Button primary={false}>Primary false</Button>
    """
  end

  @example true
  @doc "An example for the `disabled` property"
  def disabled(assigns) do
    ~F"""
    <Button>Enabled</Button>
    <Button disabled>Disabled</Button>
    """
  end
end
