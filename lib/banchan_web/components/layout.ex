defmodule BanchanWeb.Components.Layout do
  @moduledoc """
  Standard dynamic part of the layout used for Surface LiveViews.

  We can't have these just in the layout itself because of the dynamic bits.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.{Flash, Nav}

  prop current_user, :any
  prop flashes, :string

  slot default

  def render(assigns) do
    ~F"""
    <Nav current_user={@current_user} />
    <main role="main" class="container">
      <Flash flashes={@flashes} />
      <#slot />
    </main>
    """
  end
end
