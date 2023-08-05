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
      <span>{studio.name}</span>
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
      <details class="flex grow p-0" :on-click-away={JS.remove_attribute("open")}>
        <summary class="flex flex-row items-center">
          <span class="flex grow">
            {#case @context}
              {#match :client}
                {render_client_view(assigns)}
              {#match :studio}
                {render_studio_view(assigns, @studio)}
              {#match :admin}
                {render_admin_view(assigns)}
              {#match :dev}
                {render_dev_view(assigns)}
            {/case}
          </span>
          <Icon name="chevron-down" />
        </summary>
        <ul class="p-2 menu absolute left-0 z-[1] bg-base-100 rounded-box w-full bordered border-base-300">
          <li>
            <LiveRedirect to={~p"/"}>
              {render_client_view(assigns)}
            </LiveRedirect>
          </li>
          {#for studio <- studios}
            <li>
              <LiveRedirect to={~p"/studios/#{studio.handle}"}>
                {render_studio_view(assigns, studio)}
              </LiveRedirect>
            </li>
          {/for}
          {#if Accounts.active_user?(@current_user) && Accounts.admin?(@current_user)}
            <li>
              <LiveRedirect to={~p"/admin/denizens"}>
                {render_admin_view(assigns)}
              </LiveRedirect>
            </li>
            <li>
              {!-- # TODO: dev landing page --}
              <LiveRedirect to={~p"/admin/denizens"}>
                {render_dev_view(assigns)}
              </LiveRedirect>
            </li>
          {/if}
        </ul>
      </details>
    </bc-view-switcher>
    """
  end
end
