defmodule BanchanWeb.Components.Avatar do
  @moduledoc """
  Component for displaying a user.
  """
  use BanchanWeb, :component

  alias Banchan.Accounts

  alias Surface.Components.LiveRedirect

  prop user, :struct, required: true
  prop link, :boolean, default: true
  prop thumb, :boolean, default: true
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <div class={"avatar", placeholder: is_nil(@user) || !@user.pfp_thumb_id}>
      <div class={
        "rounded-full",
        @class,
        "bg-neutral-focus text-neutral-content": is_nil(@user) || !@user.pfp_thumb_id
      }>
        {#if !Accounts.active_user?(@user)}
          <div class="w-full h-full bg-neutral-focus" />
        {#elseif @link}
          <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @user.handle)}>
            {#if @thumb && @user.pfp_thumb_id}
              <img src={Routes.public_image_path(Endpoint, :image, :user_pfp_thumb, @user.pfp_thumb_id)}>
            {#elseif !@thumb && @user.pfp_img_id}
              <img src={Routes.public_image_path(Endpoint, :image, :user_pfp_img, @user.pfp_img_id)}>
            {#else}
              <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
            {/if}
          </LiveRedirect>
        {#else}
          {#if @user.pfp_thumb_id}
            <img src={Routes.public_image_path(Endpoint, :image, :user_pfp_thumb, @user.pfp_thumb_id)}>
          {#else}
            <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
          {/if}
        {/if}
      </div>
    </div>
    """
  end
end
