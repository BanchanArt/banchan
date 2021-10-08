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
  prop price_range, :string

  def render(assigns) do
    ~F"""
    <Card class="commission-card">
      <:header>
        {@name}
      </:header>
      <:image>
        {!-- TODO: I feel like we need to do something here if we're going to have these cards render right --}
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
        {!-- TODO: hook up type_id --}
        <LiveRedirect
          class="button is-primary card-footer-item"
          to={Routes.commission_new_path(Endpoint, :new, @studio.slug, type: @type_id)}
        >Details</LiveRedirect>
      </:footer>
    </Card>
    """
  end
end
