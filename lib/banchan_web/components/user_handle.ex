defmodule BanchanWeb.Components.UserHandle do
  @moduledoc """
  Renders the text/link for a user handle.
  """
  use BanchanWeb, :component

  alias Banchan.Accounts

  alias Surface.Components.LiveRedirect

  prop user, :struct, required: true
  prop link, :boolean, default: true

  def render(assigns) do
    ~F"""
    {#if Accounts.active_user?(@user) && @link}
      <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @user.handle)}>
        <strong title={@user.name} class="font-bold hover:underline">{@user.handle}</strong>
      </LiveRedirect>
    {#elseif !Accounts.active_user?(@user)}
      <strong class="font-bold">(deactivated)</strong>
    {#else}
      <strong title="(deactivated)" class="font-bold hover:underline">(deactivated)</strong>
    {/if}
    """
  end
end
