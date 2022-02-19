defmodule BanchanWeb.StudioLive.Components.Commissions.Summary do
  @moduledoc """
  Summary card for the Commissions Page sidebar
  """
  use BanchanWeb, :component

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{Submit, TextArea, TextInput}

  prop line_items, :list, required: true
  prop allow_edits, :boolean, default: false
  prop offering, :struct
  prop add_item, :event
  prop remove_item, :event
  prop deposited, :struct

  prop custom_changeset, :struct
  prop open_custom, :boolean, default: false
  prop submit_custom, :event
  prop change_custom, :event
  prop toggle_custom, :event

  def render(assigns) do
    estimate =
      Enum.reduce(
        assigns.line_items,
        # TODO: Using :USD here is a bad idea for later, but idk how to do it better yet.
        Money.new(0, :USD),
        fn item, acc -> Money.add(acc, item.amount) end
      )

    ~F"""
    <div class="flex flex-col">
      <ul class="flex flex-col">
        {#for {item, idx} <- Enum.with_index(@line_items)}
          <li class="flex p-2 gap-2">
            {#if @allow_edits && !item.sticky}
              <button
                type="button"
                :on-click={@remove_item}
                value={idx}
                class="text-xl w-8 fas fa-times-circle"
              />
            {#else}
              <button
                type="button"
                disabled="true"
                title="This item cannot be removed"
                class="w-8 place-self-center text-xl fas fa-thumbtack"
              />
            {/if}
            <div class="grow flex flex-col">
              <div class="font-bold">{item.name}</div>
              <div class="text-sm">{item.description}</div>
            </div>
            <div class="p-2">{Money.to_string(item.amount)}</div>
          </li>
        {/for}
      </ul>
      <hr class="pt-2">
      {#if @deposited}
        <div class="p-2 flex flex-col">
          <div class="flex flex-row items-center">
            <div class="font-bold grow">Total:</div>
            <div class="p-2">{Money.to_string(estimate)}</div>
          </div>
          <hr class="p-2">
          <div class="flex flex-row items-center">
            <div class="font-bold grow">Deposited:</div>
            <div class="p-2">{Money.to_string(@deposited)}</div>
          </div>
          <div class="flex flex-row items-center">
            <div class="font-bold grow">Remaining Balance:</div>
            <div class="p-2">{Money.to_string(Money.subtract(estimate, @deposited))}</div>
          </div>
        </div>
      {#else}
        <div class="p-2 flex">
          <div class="font-bold grow">Estimate:</div>
          <div class="p-2">{Money.to_string(estimate)}</div>
        </div>
      {/if}
      <hr class="pt-2">
      {#if @offering && Enum.any?(@offering.options)}
        <h5 class="text-xl p-2">Add-ons:</h5>
        <ul class="flex flex-col">
          {#for {option, idx} <- Enum.with_index(@offering.options)}
            {#if option.multiple || !Enum.any?(@line_items, &(&1.option && &1.option.id == option.id))}
              <li class="flex gap-2 p-2">
                {#if @allow_edits}
                  <button type="button" :on-click={@add_item} value={idx} class="w-8 text-xl fas fa-plus-circle" />
                {#else}
                  <div class="w-8" />
                {/if}
                <div class="grow flex flex-col">
                  <div class="font-bold">{option.name}</div>
                  <div class="text-sm">{option.description}</div>
                </div>
                <div class="p-2">{Money.to_string(option.price)}</div>
              </li>
            {/if}
          {/for}
        </ul>
        {#if @custom_changeset}
          <h2 class="text-2xl">Add Custom Option</h2>
          <Form
            class="flex flex-col space-y-2"
            for={@custom_changeset}
            change={@change_custom}
            submit={@submit_custom}
          >
            <TextInput name={:name} show_label={false} opts={required: true, placeholder: "Name"} />
            <TextArea
              name={:description}
              show_label={false}
              opts={required: true, placeholder: "Description"}
            />
            <TextInput name={:amount} show_label={false} opts={required: true, placeholder: "Price"} />
            <Submit changeset={@custom_changeset} />
          </Form>
        {/if}
      {/if}
    </div>
    """
  end
end
