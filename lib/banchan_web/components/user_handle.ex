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
        <span>
          <strong title={@user.name} class="font-semibold hover:underline">@{@user.handle}</strong>
          {#if :admin in @user.roles}
            <span class="font-medium text-error">
              (admin)</span>
          {#elseif :mod in @user.roles}
            <span class="font-medium text-error">
              (mod)</span>
          {/if}
        </span>
      </LiveRedirect>
    {#elseif Accounts.active_user?(@user) && !@link}
      <span class="cursor-default">
        <strong title={@user.name} class="font-semibold">@{@user.handle}</strong>
        {#if :admin in @user.roles}
          <span class="font-medium text-error">
            (admin)</span>
        {#elseif :mod in @user.roles}
          <span class="font-medium text-error">
            (mod)</span>
        {/if}
      </span>
    {#else}
      <strong title="User deactivated their account" class="font-semibold">(deactivated)</strong>
    {/if}
    """
  end
end
