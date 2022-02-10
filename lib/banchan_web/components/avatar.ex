defmodule BanchanWeb.Components.Avatar do
  @moduledoc """
  Component for displaying a user.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  prop user, :struct, required: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <div class={"avatar", placeholder: !@user.pfp_thumb_id}>
      <div class={@class, "bg-neutral-focus text-neutral-content": !@user.pfp_thumb_id}>
        <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @user.handle)}>
          {#if @user.pfp_thumb_id}
            <img src={Routes.profile_image_path(Endpoint, :thumb, @user.handle)} class="mask mask-circle">
          {#else}
            <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
          {/if}
        </LiveRedirect>
      </div>
    </div>
    """
  end
end
