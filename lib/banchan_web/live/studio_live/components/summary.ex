defmodule BanchanWeb.StudioLive.Components.Commissions.Summary do
  @moduledoc """
  Summary card for the Commissions Page sidebar
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Card

  prop line_items, :list, required: true
  prop allow_edits, :boolean, default: false
  prop offering, :struct
  prop add_item, :event
  prop remove_item, :event

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        Summary
      </:header>

      <ul class="divide-y">
        {#for {item, idx} <- Enum.with_index(@line_items)}
          <li class="line-item container p-4">
            <div class="float-right">
              {Money.to_string(item.amount)}
              {#if @allow_edits && !item.sticky}
                <button :on-click="remove_item" value={idx} class="fas fa-times-circle" />
              {/if}
            </div>
            <div>{item.name}</div>
            <div>{item.description}</div>
          </li>
        {/for}
      </ul>
      <hr>
      <div class="container">
        <p class="p-4">Estimate: <span class="float-right">
            {Money.to_string(
              Enum.reduce(
                @line_items,
                # TODO: Using :USD here is a bad idea for later, but idk how to do it better yet.
                Money.new(0, :USD),
                fn item, acc -> Money.add(acc, item.amount) end
              )
            )}
          </span></p>
      </div>
      <:footer>
        {#if @offering && Enum.any?(@offering.options)}
          <hr>
          <h5>Additional Options</h5>
          <ul>
            {#for {option, idx} <- Enum.with_index(@offering.options)}
              {#if option.multiple || !Enum.any?(@line_items, &(&1.option.id == option.id))}
                <li>
                  <span>{to_string(option.price)}</span>
                  <span>{option.name}</span>
                  {#if @allow_edits}
                    <button :on-click="add_item" value={idx} class="fas fa-plus-circle" />
                  {/if}
                </li>
              {/if}
            {/for}
          </ul>
        {/if}
      </:footer>
    </Card>
    """
  end
end
