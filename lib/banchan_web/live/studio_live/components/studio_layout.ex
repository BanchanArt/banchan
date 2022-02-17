defmodule BanchanWeb.StudioLive.Components.StudioLayout do
  @moduledoc """
  Shared layout component between the various Studio-related pages.
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.TabButton

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop flashes, :string, required: true
  prop studio, :struct, required: true
  prop tab, :atom

  slot default

  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flashes}>
      <:hero>
        <section class="bg-secondary">
          <div class="ml-8 col-span-12">
            <p class="text-3xl text-secondary-content font-bold flex-grow">
              {@studio.name}
            </p>
            <p class="text-base text-secondary-content flex-grow">
              {@studio.description}
              {!-- TODO: add in follow functionality --}
              <a href="/" class="btn glass btn-sm text-center rounded-full px-2 py-0" label="Follow">Follow</a>
            </p>
            <br>
          </div>
          <div class="overflow-auto min-w-screen">
            <nav class="tabs px-2 flex flex-nowrap">
              <TabButton
                studio={@studio}
                label="Shop"
                tab_name={:shop}
                current_tab={@tab}
                to={Routes.studio_shop_path(Endpoint, :show, @studio.handle)}
              />
              <TabButton
                studio={@studio}
                label="About"
                tab_name={:about}
                current_tab={@tab}
                to={Routes.studio_about_path(Endpoint, :show, @studio.handle)}
              />
              <TabButton
                studio={@studio}
                label="Portfolio"
                tab_name={:portfolio}
                current_tab={@tab}
                to={Routes.studio_portfolio_path(Endpoint, :show, @studio.handle)}
              />
              <TabButton
                studio={@studio}
                label="Q&A"
                tab_name={:qa}
                current_tab={@tab}
                to={Routes.studio_qa_path(Endpoint, :show, @studio.handle)}
              />
              {#if @current_user_member?}
                <TabButton
                  studio={@studio}
                  label="Settings"
                  tab_name={:settings}
                  current_tab={@tab}
                  to={Routes.studio_settings_path(Endpoint, :show, @studio.handle)}
                />
              {/if}
            </nav>
          </div>
        </section>
      </:hero>
      <#slot />
    </Layout>
    """
  end
end
