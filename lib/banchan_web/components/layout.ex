defmodule BanchanWeb.Components.Layout do
  @moduledoc """
  Standard dynamic part of the layout used for Surface LiveViews.

  We can't have these just in the layout itself because of the dynamic bits.
  """
  use BanchanWeb, :component

  alias Banchan.Accounts

  alias Surface.Components.{Link, LiveRedirect}

  alias BanchanWeb.Components.{Flash, Icon, Nav}

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
        <div class="sticky top-0 z-50">
          <Nav />
        </div>
        {#if slot_assigned?(:hero)}
          <#slot {@hero} />
        {/if}
        <section class={"flex flex-col w-full flex-grow p-#{@padding}"}>
          <div class="w-full mx-auto max-w-7xl grow">
            <div class="my-2 alert alert-info" :if={@current_user && is_nil(@current_user.confirmed_at)}>
              <div class="block">
                ⚠️You need to verify your email address before you can do certain things on the site, such as submit new commissions. Please check your email or <LiveRedirect class="link" to={Routes.confirmation_path(Endpoint, :show)}>click here to resend your confirmation</LiveRedirect>.⚠️
              </div>
            </div>
            <Flash flashes={@flashes} />
            <#slot />
          </div>
        </section>
        <div class="w-full h-auto border-t border-base-content border-opacity-10 bg-base-200">
          <footer class="w-full p-10 mx-auto bg-transparent footer max-w-7xl">
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
                <a
                  href="https://mastodon.art/@Banchan"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="hover:text-primary active:text-primary active:translate-y-0.5"
                >
                  <svg role="img" width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <title>Mastodon</title>
                    <path
                      fill="currentColor"
                      d="M23.268 5.313c-.35-2.578-2.617-4.61-5.304-5.004C17.51.242 15.792 0 11.813 0h-.03c-3.98 0-4.835.242-5.288.309C3.882.692 1.496 2.518.917 5.127.64 6.412.61 7.837.661 9.143c.074 1.874.088 3.745.26 5.611.118 1.24.325 2.47.62 3.68.55 2.237 2.777 4.098 4.96 4.857 2.336.792 4.849.923 7.256.38.265-.061.527-.132.786-.213.585-.184 1.27-.39 1.774-.753a.057.057 0 0 0 .023-.043v-1.809a.052.052 0 0 0-.02-.041.053.053 0 0 0-.046-.01 20.282 20.282 0 0 1-4.709.545c-2.73 0-3.463-1.284-3.674-1.818a5.593 5.593 0 0 1-.319-1.433.053.053 0 0 1 .066-.054c1.517.363 3.072.546 4.632.546.376 0 .75 0 1.125-.01 1.57-.044 3.224-.124 4.768-.422.038-.008.077-.015.11-.024 2.435-.464 4.753-1.92 4.989-5.604.008-.145.03-1.52.03-1.67.002-.512.167-3.63-.024-5.545zm-3.748 9.195h-2.561V8.29c0-1.309-.55-1.976-1.67-1.976-1.23 0-1.846.79-1.846 2.35v3.403h-2.546V8.663c0-1.56-.617-2.35-1.848-2.35-1.112 0-1.668.668-1.67 1.977v6.218H4.822V8.102c0-1.31.337-2.35 1.011-3.12.696-.77 1.608-1.164 2.74-1.164 1.311 0 2.302.5 2.962 1.498l.638 1.06.638-1.06c.66-.999 1.65-1.498 2.96-1.498 1.13 0 2.043.395 2.74 1.164.675.77 1.012 1.81 1.012 3.12z"
                    />
                  </svg>
                </a>
                <a
                  href="https://twitter.com/BanchanArt"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="hover:text-primary active:text-primary active:translate-y-0.5"
                >
                  <svg role="img" width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <title>Twitter</title>
                    <path
                      fill="currentColor"
                      d="M21.543 7.104c.015.211.015.423.015.636 0 6.507-4.954 14.01-14.01 14.01v-.003A13.94 13.94 0 0 1 0 19.539a9.88 9.88 0 0 0 7.287-2.041 4.93 4.93 0 0 1-4.6-3.42 4.916 4.916 0 0 0 2.223-.084A4.926 4.926 0 0 1 .96 9.167v-.062a4.887 4.887 0 0 0 2.235.616A4.928 4.928 0 0 1 1.67 3.148 13.98 13.98 0 0 0 11.82 8.292a4.929 4.929 0 0 1 8.39-4.49 9.868 9.868 0 0 0 3.128-1.196 4.941 4.941 0 0 1-2.165 2.724A9.828 9.828 0 0 0 24 4.555a10.019 10.019 0 0 1-2.457 2.549z"
                    />
                  </svg>
                </a>
                <a
                  href="https://discord.gg/FUkTHjGKJF"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="hover:text-primary active:text-primary active:translate-y-0.5"
                >
                  <svg role="img" width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <title>Discord</title>
                    <path
                      fill="currentColor"
                      d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"
                    />
                  </svg>
                </a>
                <a
                  href="https://github.com/BanchanArt/banchan"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="hover:text-primary active:text-primary active:translate-y-0.5"
                >
                  <svg role="img" width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <title>GitHub</title>
                    <path
                      fill="currentColor"
                      d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"
                    />
                  </svg>
                </a>
              </div>
            </div>
          </footer>
        </div>
      </div>

      {!-- # TODO: remove this basic auth check on launch --}
      <div
        :if={@current_user || is_nil(Application.get_env(:banchan, :basic_auth))}
        class="drawer-side"
      >
        <label for="drawer-toggle" class="drawer-overlay" />
        <nav class="w-64 border-r shadow bg-base-200 border-base-content border-opacity-10">
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
                    <span>Log out</span>
                  </Icon>
                </Link>
              </li>
            {#else}
              <li>
                <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
                  <Icon name="log-in" size="4">
                    <span>Log in</span>
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
        </nav>
      </div>
    </div>
    """
  end
end
