defmodule BanchanWeb.Components.ViewSwitcher do
  @moduledoc """
  Sidenav dropdown for switching view contexts.
  """
  use BanchanWeb, :component

  alias Banchan.{Accounts, Studios}

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Icon

  prop current_user, :any, from_context: :current_user
  prop context, :atom, required: true
  prop studio, :struct

  def render_client_view(assigns) do
    ~F"""
    <Icon name="user" class="grow" size="4">
      <span class="grow">Client</span>
    </Icon>
    """
  end

  def render_studio_view(assigns, studio) do
    ~F"""
    <Icon name="palette" class="grow" size="4">
      <span class="text-ellipsis">{studio.name}</span>
    </Icon>
    """
  end

  def render_admin_view(assigns) do
    ~F"""
    <Icon name="gavel" class="grow" size="4">
      <span>Admin</span>
    </Icon>
    """
  end

  def render_dev_view(assigns) do
    ~F"""
    <Icon name="terminal" class="grow" size="4">
      <span>Dev</span>
    </Icon>
    """
  end

  def render(assigns) do
    studios =
      if Accounts.active_user?(assigns.current_user) &&
           Accounts.artist?(assigns.current_user) do
        Studios.list_studios(
          with_member: assigns.current_user,
          current_user: assigns.current_user,
          include_own_archived?: true,
          page_size: 24,
          order_by: :newest
        )
      else
        []
      end

    ~F"""
    <bc-view-switcher>
      {!-- # TODO: do this with JS to avoid weird padding issue with <details> --}
      <details class="flex p-0 grow" :on-click-away={JS.remove_attribute("open")}>
        <summary class="flex flex-row items-center">
          <span class="flex grow">
            {#case @context}
              {#match :client}
                {render_client_view(assigns)}
              {#match :admin}
                {render_admin_view(assigns)}
              {#match :dev}
                {render_dev_view(assigns)}
              {#match :studio}
                {render_studio_view(assigns, @studio)}
            {/case}
          </span>
          <Icon name="chevron-down" />
        </summary>
        <ul class="p-2 menu absolute left-0 mt-4 z-[1] bg-base-100 rounded-box w-full bordered border-base-300">
          <li>
            <LiveRedirect to={~p"/"} class={active: @context == :client}>
              {render_client_view(assigns)}
            </LiveRedirect>
          </li>
          {#if Accounts.active_user?(@current_user) && Accounts.mod?(@current_user)}
            <li>
              <LiveRedirect to={~p"/admin/denizens"} class={active: @context == :admin}>
                {render_admin_view(assigns)}
              </LiveRedirect>
            </li>
          {/if}
          {#if Accounts.active_user?(@current_user) && Accounts.admin?(@current_user)}
            <li>
              <LiveRedirect to={~p"/admin/dev"} class={active: @context == :dev}>
                {render_dev_view(assigns)}
              </LiveRedirect>
            </li>
          {/if}
          {#if Accounts.active_user?(@current_user) && Accounts.artist?(@current_user)}
            <li class="menu-title">Studios</li>
            {#for studio <- studios}
              <li>
                <LiveRedirect
                  to={~p"/studios/#{studio.handle}"}
                  class={active: @context == :studio && studio.id == @studio.id}
                >
                  {render_studio_view(assigns, studio)}
                </LiveRedirect>
              </li>
            {/for}
            <li>
              <LiveRedirect to={~p"/studios/new"}>
                <Icon name="plus" class="grow" size="4">
                  <span class="text-ellipsis">New Studio</span>
                </Icon>
              </LiveRedirect>
            </li>
          {/if}
        </ul>
      </details>
    </bc-view-switcher>
    """
  end
end
