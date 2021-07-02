defmodule Banchan.Components.Layout do
  @moduledoc false
  use BanchanWeb, :component

  alias Banchan.Components.{Flash, Session}

  prop current_user, :any
  prop flashes, :string

  slot default

  def render(assigns) do
    ~F"""
    <Session current_user={@current_user} />
    <main role="main" class="container">
      <Flash flashes={@flashes} />
      <#slot />
    </main>
    """
  end
end
