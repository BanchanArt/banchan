defmodule BanchanWeb.StudioLive.Components.CommissionLayout do
  @moduledoc """
  Layout component for the multi-tab Commissions page.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  prop studio, :struct, required: true
  prop current_user, :any
  prop current_user_member?, :boolean
  prop flashes, :string

  slot default, required: true

  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flashes}>
      <:hero>
        <section class="grid grid-cols-2 bg-secondary">
          <div class="ml-8 col-span-12">
            <p class="text-3xl text-secondary-content font-bold flex-grow">
              {@studio.name}
            </p>
            <p class="text-base text-secondary-content flex-grow">
              {@studio.description}
              {#if @current_user_member?}
                <LiveRedirect
                  class="btn glass btn-sm text-center rounded-full px-2 py-0"
                  label="Edit Profile"
                  to={Routes.studio_edit_path(Endpoint, :edit, @studio.handle)}
                />
              {#else}
                {!-- TODO: add in follow functionality --}
                <a
                  href="/"
                  class="btn glass btn-sm text-center rounded-full px-2 py-0"
                  label="Follow"
                >Follow</a>
              {/if}
            </p>
            <br>
          </div>
          <nav class="tabs ml-8 col-span-1 grid-cols-4 inline-grid">
            <div class="tab tab-bordered tab-active bg-primary-focus text-center rounded-t-lg text-secondary-content"><a>Shop</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>About</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Portfolio</a></div>
            <div class="tab tab-bordered bg-primary bg-opacity-60 text-center rounded-t-lg text-secondary-content"><a>Q&A</a></div>
          </nav>
        </section>
      </:hero>
      <div class="grid grid-cols-3 justify-items-stretch gap-6">
        <#slot />
      </div>
    </Layout>
    """
  end
end
