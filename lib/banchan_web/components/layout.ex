defmodule BanchanWeb.Components.Layout do
  @moduledoc """
  Standard dynamic part of the layout used for Surface LiveViews.

  We can't have these just in the layout itself because of the dynamic bits.
  """
  use BanchanWeb, :component

  alias Surface.Components.{Link, LiveRedirect}

  alias BanchanWeb.Components.{Flash, Nav}

  prop current_user, :any
  prop flashes, :string
  prop uri, :string, required: true
  prop padding, :string, default: "4"

  slot hero
  slot default

  def render(assigns) do
    ~F"""
    <div class="drawer drawer-mobile h-screen w-full">
      <input type="checkbox" id="drawer-toggle" class="drawer-toggle">
      <div class="drawer-content h-screen flex flex-col">
        <div class="top-0 z-30 sticky shadow-sm">
          <Nav uri={@uri} current_user={@current_user} />
        </div>
        {#if slot_assigned?(:hero)}
          <#slot name="hero" />
        {/if}
        <section class={"flex flex-col flex-grow p-#{@padding} shadow-inner"}>
          <Flash flashes={@flashes} />
          <#slot />
        </section>
        <footer class="footer p-10 z-30 shadow-sm">
          <div>
            <span class="footer-title">Co-op</span>
            {!-- # TODO: Fill these out --}
            <a href="#" class="link link-hover">About us</a>
            <a href="#" class="link link-hover">Contact</a>
            <a href="#" class="link link-hover">Membership</a>
            <a href="#" class="link link-hover">Press kit</a>
          </div>
          <div>
            {!-- # TODO: Fill these out --}
            <span class="footer-title">Legal</span>
            <a href="#" class="link link-hover">Terms of use</a>
            <a href="#" class="link link-hover">Privacy policy</a>
            <a href="#" class="link link-hover">Cookie policy</a>
          </div>
          <div>
            <span class="footer-title">Social</span>
            <div class="grid grid-flow-col gap-4">
              <a href="https://twitter.com/BanchanArt"><i class="fab fa-twitter text-xl" /></a>
              <a href="https://discord.gg/jgat3hsX5V"><i class="fab fa-discord text-xl" /></a>
            </div>
          </div>
        </footer>
      </div>
      <div :if={!is_nil(@current_user)} class="drawer-side">
        <label for="drawer-toggle" class="drawer-overlay" />
        <aside class="bg-base-200 w-48 shadow">
          <ul tabindex="0" class="menu flex flex-col p-2 gap-2">
            <li>
              <LiveRedirect to={Routes.home_path(Endpoint, :index)}>
                <span>
                  <i class="fas fa-home" />
                  Home
                </span>
              </LiveRedirect>
            </li>
            {#if :admin in @current_user.roles}
              <li class="menu-title">
                <span>Admin</span>
              </li>
              <li>
                <LiveRedirect to="/admin/dashboard">
                  <span>
                    <i class="fas fa-tachometer-alt" />
                    Dashboard
                  </span>
                </LiveRedirect>
              </li>
              {#if Mix.env() == :dev}
                <li>
                  <LiveRedirect to="/admin/sent_emails">
                    <span>
                      <i class="fas fa-paper-plane" />
                      Sent Emails
                    </span>
                  </LiveRedirect>
                </li>
              {/if}
            {/if}
            {#if @current_user}
              <li class="menu-title">
                <span>Art</span>
              </li>
              <li>
                <a href="#">
                  <span>
                    <i class="fas fa-search" />
                    Discover
                  </span>
                </a>
              </li>
              <li>
                <LiveRedirect to={Routes.commission_path(Endpoint, :index)}>
                  <span>
                    <i class="fas fa-palette" />
                    Commissions
                  </span>
                </LiveRedirect>
              </li>
              <li>
                <a href="#">
                  <span>
                    <i class="fas fa-list" />
                    Subscriptions
                  </span>
                </a>
              </li>
              <li>
                <LiveRedirect to={Routes.studio_index_path(Endpoint, :index)}>
                  <span>
                    <i class="fas fa-paint-brush" />
                    Studios
                  </span>
                </LiveRedirect>
              </li>
              <li class="menu-title">
                <span>Account</span>
              </li>
              <li>
                <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)}>
                  <span>
                    <i class="fas fa-user-circle" />
                    Your Profile
                  </span>
                </LiveRedirect>
              </li>
              <li>
                <a href="#">
                  <span>
                    <i class="fas fa-comment-alt" />
                    Messages
                  </span>
                </a>
              </li>
              <li>
                <LiveRedirect to={Routes.settings_path(Endpoint, :edit)}>
                  <span>
                    <i class="fas fa-cog" />
                    Settings
                  </span>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.setup_mfa_path(Endpoint, :edit)}>
                  <span>
                    <i class="fas fa-shield" />
                    MFA Setup
                  </span>
                </LiveRedirect>
              </li>
              <li>
                <Link to={Routes.user_session_path(Endpoint, :delete)} method={:delete}>
                  <span>
                    <i class="fa fa-sign-out-alt" />
                    Log out
                  </span>
                </Link>
              </li>
            {/if}
          </ul>
        </aside>
      </div>
    </div>
    """
  end
end
