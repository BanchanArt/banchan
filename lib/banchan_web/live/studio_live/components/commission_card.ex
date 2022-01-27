defmodule BanchanWeb.StudioLive.Components.CommissionCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  prop studio, :struct, required: true
  prop offering, :struct, required: true

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        {@offering.name}
      </:header>
      <:header_aside>
        {#if @offering.open}
          <span class="bg-primary p-1">Open</span>
        {#else}
          <span class="bg-secondary p-1">Closed</span>
        {/if}
      </:header_aside>
      <:image>
        <img class="object-cover" src={Routes.static_path(Endpoint, "/images/640x360.png")}>
      </:image>
      <div class="content">
        <p>{@offering.description}</p>
        Base Price:
        {#if @offering.base_price}
          <span class="float-right">{@offering.base_price}</span>
        {#else}
          <span class="float-right">Inquire</span>
        {/if}
      </div>
      <:footer>
        {#if @offering.open}
          <LiveRedirect to={Routes.studio_proposal_path(Endpoint, :show, @studio.handle, @offering.type)}>Request</LiveRedirect>
        {#else}
          <LiveRedirect to="#">Notify Me</LiveRedirect>
        {/if}
      </:footer>
    </Card>
    """
  end
end
