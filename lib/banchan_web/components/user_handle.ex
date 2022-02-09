defmodule BanchanWeb.Components.UserHandle do
  @moduledoc """
  Renders the text/link for a user handle.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop user, :struct, required: true

  def render(assigns) do
    ~F"""
    <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @user.handle)}>
      <strong title={@user.name} class="font-bold hover:underline">{@user.handle}</strong>
    </LiveRedirect>
    """
  end
end
