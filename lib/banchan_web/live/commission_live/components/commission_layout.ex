defmodule BanchanWeb.CommissionLive.Components.CommissionLayout do
  @moduledoc """
  Layout for commission and its various tabs.
  """
  use BanchanWeb, :component

  alias BanchanWeb.CommissionLive.Components.StudioLayout

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
        <h1 class="text-3xl pt-4 px-4">{@commission.title}</h1>
        <div class="divider" />
        <div class="p-2">
          <#slot />
        </div>
      </div>
    </StudioLayout>
    """
  end
end
