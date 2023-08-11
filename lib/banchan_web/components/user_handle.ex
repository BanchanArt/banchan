defmodule BanchanWeb.Components.UserHandle do
  @moduledoc """
  Renders the text/link for a user handle.
  """
  use BanchanWeb, :component

  alias Banchan.Accounts

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Icon

  prop user, :struct, required: true
  prop link, :boolean, default: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    {#if Accounts.active_user?(@user) && @link}
      <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @user.handle)}>
        <span class={"inline-flex items-center gap-1", @class}>
          <strong title={@user.name} class="font-semibold hover:underline">{@user.handle}</strong>
          {#if :admin in @user.roles}
            <div class="tooltip tooltip-right" data-tip="Admin">
              <Icon name="shield-check" size="4" class="text-error">
              </Icon>
            </div>
          {#elseif :mod in @user.roles}
            <div class="tooltip tooltip-right" data-tip="Moderator">
              <Icon name="gavel" size="4" class="text-warning">
              </Icon>
            </div>
          {#elseif :system in @user.roles}
            <div class="tooltip tooltip-right" data-tip="System">
              <Icon name="bot" size="4" class="text-primary">
              </Icon>
            </div>
          {/if}
        </span>
      </LiveRedirect>
    {#elseif Accounts.active_user?(@user) && !@link}
      <span class={"inline-flex items-center gap-1", @class}>
        <strong title={@user.name} class="font-semibold">
          {@user.handle}
        </strong>
        {#if :admin in @user.roles}
          <div class="tooltip tooltip-right" data-tip="Admin">
            <Icon name="shield-check" size="4" class="text-error">
            </Icon>
          </div>
        {#elseif :mod in @user.roles}
          <div class="tooltip tooltip-right" data-tip="Moderator">
            <Icon name="gavel" size="4" class="text-warning">
            </Icon>
          </div>
        {#elseif :system in @user.roles}
          <div class="tooltip tooltip-right" data-tip="System">
            <Icon name="bot" size="4" class="text-primary">
            </Icon>
          </div>
        {/if}
      </span>
    {#else}
      <strong title="User deactivated their account" class="font-semibold">
        <div class="tooltip tooltip-right" data-tip="Deactivated">
          <Icon name="circle-slash" size="4" class="text-primary">
          </Icon>
        </div>
      </strong>
    {/if}
    """
  end
end
