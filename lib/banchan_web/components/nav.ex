defmodule BanchanWeb.Components.Nav do
  @moduledoc """
  Handles session-related top menu items.
  """
  use BanchanWeb, :component

  alias Surface.Components.{Link, LiveRedirect}

  alias BanchanWeb.Endpoint

  prop current_user, :any

  def render(assigns) do
    ~F"""
    <nav
      id="nav"
      class="navbar bg-primary text-primary-content align-top w-full leading-snug m-0 p-0"
      role="navigation"
      aria-label="main navigation"
    >
      <div class="md:container md:mx-auto flex items-center gap-12 justify-start px-6">
        <div class="navbar-start">
          <a href="/">
            <img
              src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}
              class="inline-block object-scale-down h-12 p-1 rounded-full"
            /> Banchan Art
          </a>
        </div>
        <div class="navbar-end flex gap-4 items-center">
          {#if @current_user}
            <LiveRedirect to={Routes.dashboard_path(Endpoint, :index)}>
              <span>
                <i class="fa fa-paintbrush" />
                Dashboard
              </span>
            </LiveRedirect>
            <LiveRedirect to={Routes.studio_index_path(Endpoint, :index)}>
              <span>
                <i class="fa fa-palette" />
                Studios
              </span>
            </LiveRedirect>
            <div>
              <div class="dropdown dropdown-end">
                <div tabindex="0" class="">
                  <span>
                    <i class="fa fa-user" />
                    @{@current_user.handle}
                  </span>
                </div>
                <ul tabindex="0" class="p-2 shadow menu dropdown-content bg-primary rounded-box w-52">
                  <li>
                    <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)}>
                      <span>
                        Your Profile
                      </span>
                    </LiveRedirect>
                  </li>
                  <li>
                    <LiveRedirect to={Routes.settings_path(Endpoint, :edit)}>
                      <span>
                        <i class="fa fa-cog" />
                        Settings
                      </span>
                    </LiveRedirect>
                  </li>
                  <li>
                    <LiveRedirect to={Routes.setup_mfa_path(Endpoint, :edit)}>
                      <span>
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
                </ul>
              </div>
            </div>
          {#else}
            <LiveRedirect label="Register" to={Routes.register_path(Endpoint, :new)}>
              <span>
                <i class="fa fa-user" />
                Register
              </span>
            </LiveRedirect>
            <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
              <span>
                <i class="fa fa-sign-in-alt" />
                Log in
              </span>
            </LiveRedirect>
          {/if}
        </div>
      </div>
    </nav>
    """
  end
end
