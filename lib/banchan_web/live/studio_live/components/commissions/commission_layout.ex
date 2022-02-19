defmodule BanchanWeb.StudioLive.Components.Commissions.CommissionLayout do
  @moduledoc """
  Layout for commission and its various tabs.
  """
  use BanchanWeb, :component

  alias BanchanWeb.StudioLive.Components.{StudioLayout, TabButton}

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop flashes, :any, required: true
  prop studio, :struct, required: true
  prop commission, :struct, required: true
  prop tab, :atom, required: true

  slot default

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flashes}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:shop}
    >
      <div class="md:container md:mx-auto">
        <h1 class="text-3xl p-4">{@commission.title}</h1>
        <hr class="p-2">
        <nav class="tabs px-2 flex flex-nowrap">
          <TabButton
            label="Timeline"
            tab_name={:timeline}
            current_tab={@tab}
            to={Routes.studio_commissions_timeline_path(Endpoint, :show, @studio.handle, @commission.public_id)}
          />
          <TabButton
            label="Summary"
            tab_name={:summary}
            current_tab={@tab}
            to={Routes.studio_commissions_summary_path(Endpoint, :show, @studio.handle, @commission.public_id)}
          />
        </nav>
        <div class="p-2">
          <#slot />
        </div>
      </div>
    </StudioLayout>
    """
  end
end
