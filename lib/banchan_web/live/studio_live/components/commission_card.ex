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
    <Card class="commission-card">
      <:header>
        {@name}
      </:header>
      <:header_aside>
        {#if @open}
          <span class="tag is-medium is-success is-light">Open</span>
        {#else}
          <span class="tag is-medium is-danger is-light">Closed</span>
        {/if}
      </:header_aside>
      <:image>
        <figure class="commission-image image">
          <img src={@image}>
        </figure>
      </:image>
      <div class="content">
        <p class="commission-description">{@description}</p>
        {#if @price_range}
          <p class="price-range defined">{@price_range}</p>
        {#else}
          <p class="price-range undefined">Inquire</p>
        {/if}
      </div>
      <:footer>
        {#if @open}
          <LiveRedirect
            class="button is-primary card-footer-item"
            to={Routes.commission_new_path(Endpoint, :new, @studio.slug, type: @type_id)}
          >Request</LiveRedirect>
        {#else}
          <LiveRedirect
            class="button is-info card-footer-item"
            to="#"
          >Notify Me</LiveRedirect>
        {/if}
      </:footer>
    </Card>
    """
  end
end
