defmodule BanchanWeb.Components.Layout do
  @moduledoc """
  Standard dynamic part of the layout used for Surface LiveViews.

  We can't have these just in the layout itself because of the dynamic bits.
  """
  use BanchanWeb, :component

  alias Banchan.Accounts

  alias Surface.Components.{Link, LiveRedirect}

  alias BanchanWeb.Components.{Flash, Nav, Icon}

  prop current_user, :any, from_context: :current_user
  prop flashes, :any, required: true
  prop padding, :integer, default: 4

  slot hero
  slot default

  def render(assigns) do
    ~F"""
    <div class="w-full h-screen drawer drawer-mobile">
      <input type="checkbox" id="drawer-toggle" class="drawer-toggle">
      <div class="flex flex-col flex-grow h-screen drawer-content">
        <div class="sticky top-0 z-50 shadow-sm">
          <Nav />
        </div>
        {#if slot_assigned?(:hero)}
          <#slot {@hero} />
        {/if}
        <section class={"flex flex-col flex-grow p-#{@padding} shadow-inner"}>
          <div class="my-2 alert alert-info" :if={@current_user && is_nil(@current_user.confirmed_at)}>
            <div class="block">
              ⚠️You need to verify your email address before you can do certain things on the site, such as submit new commissions. Please check your email or <LiveRedirect class="link" to={Routes.confirmation_path(Endpoint, :show)}>click here to resend your confirmation</LiveRedirect>.⚠️
            </div>
          </div>
          <Flash flashes={@flashes} />
          <#slot />
        </section>
        <footer class="p-10 shadow-sm footer">
          <div>
            <span class="footer-title">Co-op</span>
            <LiveRedirect to={Routes.static_about_us_path(Endpoint, :show)} class="link link-hover">About Us</LiveRedirect>
            <LiveRedirect to={Routes.static_contact_path(Endpoint, :show)} class="link link-hover">Contact</LiveRedirect>
            <LiveRedirect to={Routes.static_membership_path(Endpoint, :show)} class="link link-hover">Membership</LiveRedirect>
          </div>
          <div>
            <span class="footer-title">Legal</span>
            <LiveRedirect
              to={Routes.static_terms_and_conditions_path(Endpoint, :show)}
              class="link link-hover"
            >Terms and Conditions</LiveRedirect>
            <LiveRedirect to={Routes.static_privacy_policy_path(Endpoint, :show)} class="link link-hover">Privacy policy</LiveRedirect>
            <LiveRedirect to={Routes.static_cookies_policy_path(Endpoint, :show)} class="link link-hover">Cookies policy</LiveRedirect>
            <LiveRedirect to={Routes.static_disputes_policy_path(Endpoint, :show)} class="link link-hover">Disputes Policy</LiveRedirect>
          </div>
          <div>
            <span class="footer-title">Social</span>
            <div class="grid grid-flow-col gap-4">
              <a href="https://mastodon.art/@Banchan" target="_blank" rel="noopener noreferrer"><i class="text-xl fab fa-mastodon" /></a>
              <a href="https://twitter.com/BanchanArt" target="_blank" rel="noopener noreferrer"><i class="text-xl fab fa-twitter" /></a>
              <a href="https://discord.gg/FUkTHjGKJF" target="_blank" rel="noopener noreferrer"><i class="text-xl fab fa-discord" /></a>
            </div>
          </div>
        </footer>
      </div>

      {!-- # TODO: remove this basic auth check on launch --}
      <div
        :if={@current_user || is_nil(Application.get_env(:banchan, :basic_auth))}
        class="drawer-side"
      >
        <label for="drawer-toggle" class="drawer-overlay" />
        <aside class="w-64 shadow bg-base-200">
          <ul tabindex="0" class="flex flex-col gap-2 p-2 menu menu-compact">
            <li>
              <LiveRedirect to={Routes.home_path(Endpoint, :index)}>
                <Icon name="home" size="4">
                  <span>Home</span>
                </Icon>
              </LiveRedirect>
            </li>
            {#if Accounts.active_user?(@current_user) && :admin in @current_user.roles}
              <li class="menu-title">
                <span>Admin</span>
              </li>
              <li>
                <LiveRedirect to={Routes.report_index_path(Endpoint, :index)}>
                  <Icon name="flag" size="4">
                    <span>Reports</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.denizen_index_path(Endpoint, :index)}>
                  <Icon name="users" size="4">
                    <span>Users</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.beta_requests_path(Endpoint, :index)}>
                  <Icon name="inbox" size="4">
                    <span>Beta Requests</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li>
                <a href={~p"/admin/dashboard"} target="_blank" rel="noopener noreferrer">
                  <Icon name="layout-panel-top" size="4">
                    <span>Dashboard</span>
                  </Icon>
                </a>
              </li>
              {#if Application.fetch_env!(:banchan, :env) == :dev}
                <li>
                  <a href={~p"/admin/sent_emails"} target="_blank" rel="noopener noreferrer">
                    <Icon name="mail-open" size="4">
                      <span>Sent Emails</span>
                    </Icon>
                  </a>
                </li>
                <li>
                  <a href="/catalogue" target="_blank" rel="noopener noreferrer">
                    <Icon name="component" size="4">
                      <span>Catalogue</span>
                    </Icon></a>
                </li>
              {/if}
            {/if}
            <li class="menu-title">
              <span>Art</span>
            </li>
            <li :if={Accounts.active_user?(@current_user)}>
              <LiveRedirect to={Routes.commission_path(Endpoint, :index)}>
                <Icon name="palette" size="4">
                  <span>My Commissions</span>
                </Icon>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.discover_index_path(Endpoint, :index)}>
                <Icon name="search" size="4">
                  <span>Discover</span>
                </Icon>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.discover_index_path(Endpoint, :index, "offerings")}>
                <Icon name="shopping-bag" size="4">
                  <span>Offerings</span>
                </Icon>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.discover_index_path(Endpoint, :index, "studios")}>
                <Icon name="store" size="4">
                  <span>Studios</span>
                </Icon>
              </LiveRedirect>
            </li>
            <li class="menu-title">
              <span>Account</span>
            </li>
            {#if Accounts.active_user?(@current_user)}
              <li>
                <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)}>
                  <Icon name="user" size="4">
                    <span>My Profile</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li :if={:artist not in @current_user.roles}>
                <LiveRedirect to={Routes.beta_signup_path(Endpoint, :new)}>
                  <Icon name="clipboard-signature" size="4">
                    <span>Artist Signup</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li :if={:artist in @current_user.roles}>
                <LiveRedirect to={Routes.studio_index_path(Endpoint, :index)}>
                  <Icon name="store" size="4">
                    <span>My Studios</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.settings_path(Endpoint, :edit)}>
                  <Icon name="settings" size="4">
                    <span>Settings</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.report_bug_new_path(Endpoint, :new)}>
                  <Icon name="bug" size="4">
                    <span>Report Bug</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li>
                <Link to={Routes.user_session_path(Endpoint, :delete)} method={:delete}>
                  <Icon name="log-out" size="4">
                    <span>Logout</span>
                  </Icon>
                </Link>
              </li>
            {#else}
              <li>
                <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
                  <Icon name="log-in" size="4">
                    <span>Login</span>
                  </Icon>
                </LiveRedirect>
              </li>
              <li>
                <LiveRedirect to={Routes.register_path(Endpoint, :new)}>
                  <Icon name="user-plus" size="4">
                    <span>Register</span>
                  </Icon>
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
