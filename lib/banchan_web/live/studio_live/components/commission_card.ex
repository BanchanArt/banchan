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
          <div class="badge badge-success badge-outline">Open</div>
        {#else}
          <div class="badge badge-error badge-outline">Closed</div>
        {/if}
      </:header_aside>
      <:image>
        <img class="object-cover" src={Routes.static_path(Endpoint, "/images/640x360.png")}>
      </:image>
      <div class="content">
        <p class="mt-2">{@offering.description}</p>
        <p class="text-success mt-2">
          Base Price:
          {#if @offering.base_price}
            <span class="float-right">{@offering.base_price}</span>
          {#else}
            <span class="float-right">Inquire</span>
          {/if}
        </p>
      </div>
      <:footer>
        <div class="justify-end card-actions">
          {#if @offering.open}
            <LiveRedirect
              to={Routes.studio_commissions_new_path(Endpoint, :new, @studio.handle, @offering.type)}
              class="btn btn-sm text-center btn-info"
            >Request</LiveRedirect>
          {#else}
            <LiveRedirect to="#" class="btn btn-sm text-center btn-info">Notify Me</LiveRedirect>
          {/if}
        </div>
      </:footer>
    </Card>
    """
  end
end
