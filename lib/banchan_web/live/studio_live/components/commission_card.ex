defmodule BanchanWeb.StudioLive.Components.CommissionCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  prop studio, :struct, required: true
  prop type_id, :string, required: true
  prop name, :string, required: true
  prop description, :string, required: true
  prop image, :uri, required: true
  prop open, :boolean, required: true
  prop price_range, :string

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        {@name}
      </:header>
      <:header_aside>
        {#if @open}
          <span class="bg-green-500 p-1">Open</span>
        {#else}
          <span class="bg-red-500 p-1">Closed</span>
        {/if}
      </:header_aside>
      <:image>
        <img class="object-cover" src={@image}>
      </:image>
      <div class="content">
        <p>{@description}</p>
        Price:
        {#if @price_range}
          <span class="float-right">{@price_range}</span>
        {#else}
          <span class="float-right">Inquire</span>
        {/if}
      </div>
      <:footer>
        {#if @open}
          <LiveRedirect
            to={Routes.commission_new_path(Endpoint, :new, @studio.handle, @type_id)}
          >Request</LiveRedirect>
        {#else}
          <LiveRedirect to="#">Notify Me</LiveRedirect>
        {/if}
      </:footer>
    </Card>
    """
  end
end
