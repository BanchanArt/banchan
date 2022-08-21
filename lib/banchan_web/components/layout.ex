defmodule BanchanWeb.Components.Layout do
  @moduledoc """
  Standard dynamic part of the layout used for Surface LiveViews.

  We can't have these just in the layout itself because of the dynamic bits.
  """
  use BanchanWeb, :component

  alias Banchan.Accounts

  alias Surface.Components.{Link, LiveRedirect}

  alias BanchanWeb.Components.{Flash, Nav}

  prop current_user, :any
  prop flashes, :string
  prop uri, :string, required: true
  prop padding, :integer, default: 4

  slot hero
  slot default

  def render(assigns) do
    ~F"""
    <div class="drawer drawer-mobile h-screen w-full">
      <input type="checkbox" id="drawer-toggle" class="drawer-toggle">
      <div class="drawer-content h-screen flex flex-col flex-grow">
        <div class="top-0 z-50 sticky shadow-sm">
          <Nav uri={@uri} current_user={@current_user} />
        </div>
        {#if slot_assigned?(:hero)}
          <#slot name="hero" />
        {/if}
        <section class={"flex flex-col flex-grow p-#{@padding} shadow-inner"}>
          <div class="alert alert-info my-2" :if={@current_user && is_nil(@current_user.confirmed_at)}>
            <div class="block">
              ⚠️You need to verify your email address before you can do certain things on the site, such as submit new commissions. Please check your email or <LiveRedirect class="link" to={Routes.confirmation_path(Endpoint, :show)}>click here to resend your confirmation</LiveRedirect>.⚠️
            </div>
          </div>
          <Flash flashes={@flashes} />
          <#slot />
        </section>
        <footer class="footer p-10 shadow-sm">
          <div>
            <span class="footer-title">Co-op</span>
            <LiveRedirect to={Routes.static_about_us_path(Endpoint, :show)} class="link link-hover">About Us</LiveRedirect>
            <LiveRedirect to={Routes.static_contact_path(Endpoint, :show)} class="link link-hover">Contact</LiveRedirect>
            <LiveRedirect to={Routes.static_membership_path(Endpoint, :show)} class="link link-hover">Membership</LiveRedirect>
          </div>
          <div>
            <span class="footer-title">Legal</span>
            <LiveRedirect to={Routes.static_terms_of_service_path(Endpoint, :show)} class="link link-hover">Terms of Service</LiveRedirect>
            <LiveRedirect to={Routes.static_privacy_policy_path(Endpoint, :show)} class="link link-hover">Privacy policy</LiveRedirect>
            <LiveRedirect
              to={Routes.static_refunds_and_disputes_path(Endpoint, :show)}
              class="link link-hover"
            >Refunds and Disputes</LiveRedirect>
          </div>
          <div>
            <span class="footer-title">Social</span>
            <div class="grid grid-flow-col gap-4">
              <a href="https://twitter.com/BanchanArt" target="_blank" rel="noopener noreferrer"><i class="fab fa-twitter text-xl" /></a>
              <a href="https://discord.gg/FUkTHjGKJF" target="_blank" rel="noopener noreferrer"><i class="fab fa-discord text-xl" /></a>
            </div>
          </div>
        </footer>
      </div>
      <div class="drawer-side">
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
            {#if Accounts.active_user?(@current_user) && :admin in @current_user.roles}
              <li class="menu-title">
                <span>Admin</span>
              </li>
              <li>
                <LiveRedirect to={Routes.report_index_path(Endpoint, :index)}>
                  <span>
                    <i class="fas fa-flag" />
                    Reports
                  </span>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.denizen_index_path(Endpoint, :index)}>
                  <span>
                    <i class="fas fa-user-group" />
                    Users
                  </span>
                </LiveRedirect>
              </li>
              <li>
                <a href="/admin/dashboard" target="_blank" rel="noopener noreferrer"><i class="fas fa-tachometer-alt" />Dashboard</a>
              </li>
              {#if Application.fetch_env!(:banchan, :env) == :dev}
                <li>
                  <a href="/admin/sent_emails" target="_blank" rel="noopener noreferrer"><i class="fas fa-paper-plane" />Sent Emails</a>
                </li>
              {/if}
            {/if}
            <li class="menu-title">
              <span>Art</span>
            </li>
            <li :if={Accounts.active_user?(@current_user)}>
              <LiveRedirect to={Routes.commission_path(Endpoint, :index)}>
                <span>
                  <i class="fas fa-palette" />
                  My Commissions
                </span>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.discover_index_path(Endpoint, :index)}>
                <span>
                  <i class="fas fa-search" />
                  Discover
                </span>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.discover_index_path(Endpoint, :index, "offerings")}>
                <span>
                  <i class="fas fa-paint-brush" />
                  Offerings
                </span>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.discover_index_path(Endpoint, :index, "studios")}>
                <span>
                  <i class="fas fa-store" />
                  Studios
                </span>
              </LiveRedirect>
            </li>
            <li class="menu-title">
              <span>Account</span>
            </li>
            {#if Accounts.active_user?(@current_user)}
              <li>
                <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)}>
                  <span>
                    <i class="fas fa-user-circle" />
                    Your Profile
                  </span>
                </LiveRedirect>
              </li>
              <li :if={:artist in @current_user.roles}>
                <LiveRedirect to={Routes.studio_index_path(Endpoint, :index)}>
                  <span>
                    <i class="fas fa-palette" />
                    Your Studios
                  </span>
                </LiveRedirect>
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
                <Link to={Routes.user_session_path(Endpoint, :delete)} method={:delete}>
                  <span>
                    <i class="fa fa-sign-out-alt" />
                    Log out
                  </span>
                </Link>
              </li>
            {#else}
              <li>
                <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
                  <span>
                    <i class="fas fa-sign-in-alt" />
                    Log in
                  </span>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.register_path(Endpoint, :new)}>
                  <span>
                    <i class="fas fa-user-plus" />
                    Register
                  </span>
                </LiveRedirect>
              </li>
            {/if}
          </ul>
        </aside>
      </div>
    </div>
    """
  end
end
