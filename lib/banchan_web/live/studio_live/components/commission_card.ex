defmodule BanchanWeb.StudioLive.Components.CommissionCard do
  @moduledoc """
  Card component for commissions
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Endpoint

  prop studio, :struct, required: true
  prop type_id, :string, required: true
  prop name, :string, required: true
  prop description, :string, required: true
  prop image, :uri, required: true
  prop price_range, :string
  prop total_slots, :number
  prop available_slots, :number

  def render(assigns) do
    ~F"""
    <Card class="commission-card">
      <:header>
        {@name}
      </:header>
      <:header_aside>
        {!-- TODO: change display color based on available slots --}
        {#if @total_slots}
          <span class="commission-slots tag is-medium is-danger is-light">{@available_slots}/{@total_slots} slots</span>
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
          <p class="price-range defined">$500-$1000</p>
        {#else}
          <p class="price-range undefined">Inquire</p>
        {/if}
      </div>
      <:footer>
        {!-- TODO: hook up type_id --}
        <a
          class="button is-primary card-footer-item"
          href={Routes.commission_new_path(Endpoint, :new, @studio.slug)}
        >Details</a>
      </:footer>
    </Card>
    """
  end
end
