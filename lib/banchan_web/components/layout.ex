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

  slot hero
  slot default

  def render(assigns) do
    ~F"""
    <div class="drawer drawer-end h-screen w-full">
      <input type="checkbox" id="drawer-toggle" class="drawer-toggle">
      <div class="drawer-content h-screen flex flex-col">
        <Nav uri={@uri} current_user={@current_user} />
        {#if slot_assigned?(:hero)}
          <#slot name="hero" />
        {/if}
        <section class="flex flex-col flex-grow">
          <Flash flashes={@flashes} />
          <#slot />
        </section>
        <footer class="footer p-10 bg-neutral text-neutral-content">
          <div>
            <span class="footer-title">Co-op</span>
            {!-- # TODO: Fill these out --}
            <a href="#" class="link link-hover">About us</a>
            <a href="#" class="link link-hover">Contact</a>
            <a href="#" class="link link-hover">Jobs</a>
            <a href="#" class="link link-hover">Press kit</a>
          </div>
          <div>
            {!-- # TODO: Fill these out --}
            <span class="footer-title">Legal</span>
            <a href="#" class="link link-hover">Terms of use</a>
            <a href="#" class="link link-hover">Privacy policy</a>
            <a href="#" class="link link-hover">Cookie policy</a>
          </div>
        </footer>
      </div>
      <div class="drawer-side">
        <label for="drawer-toggle" class="drawer-overlay" />
        <ul tabindex="0" class="p-2 shadow menu dropdown-content bg-base-200 w-52">
          {#if @current_user}
            <li>
              <LiveRedirect to={Routes.denizen_show_path(Endpoint, :show, @current_user.handle)}>
                <span>
                  Your Profile
                </span>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.commission_path(Endpoint, :index)}>
                <span>
                  <i class="fa fa-palette" />
                  Commissions
                </span>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.studio_index_path(Endpoint, :index)}>
                <span>
                  <i class="fa fa-palette" />
                  Studios
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
          {#else}
            <li>
              <LiveRedirect label="Register" to={Routes.register_path(Endpoint, :new)}>
                <span>
                  <i class="fa fa-user" />
                  Register
                </span>
              </LiveRedirect>
            </li>
            <li>
              <LiveRedirect to={Routes.login_path(Endpoint, :new)}>
                <span>
                  <i class="fa fa-sign-in-alt" />
                  Log in
                </span>
              </LiveRedirect>
            </li>
          {/if}
        </ul>
      </div>
    </div>
    """
  end
end
