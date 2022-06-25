defmodule BanchanWeb.CommissionLive.Components.Summary do
  @moduledoc """
  Summary card for the Commissions Page sidebar
  """
  use BanchanWeb, :component

  alias Surface.Components.Form

  alias BanchanWeb.Components.Button
  alias BanchanWeb.Components.Form.{Select, Submit, TextArea, TextInput}

  prop studio, :struct, required: true
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
  prop close_custom, :event
  prop nothing, :event

  def render(assigns) do
    estimate =
      Enum.reduce(
        assigns.line_items,
        %{},
        fn item, acc ->
          current =
            Map.get(
              acc,
              item.amount.currency,
              Money.new(0, item.amount.currency)
            )

          Map.put(acc, item.amount.currency, Money.add(current, item.amount))
        end
      )

    remaining =
      assigns.deposited
      |> Enum.map(fn {currency, amount} ->
        Money.subtract(Map.get(estimate, currency, Money.new(0, currency)), amount)
      end)

    estimate = Map.values(estimate)
    deposited = assigns.deposited |> Map.values()

    ~F"""
    <div class="flex flex-col">
      {#if @offering}
        <div class="px-2 text-2xl">{@offering.name}</div>
        <div class="px-2 text-sm">{@offering.description}</div>
        <div class="divider" />
      {/if}
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
      <div class="divider" />
      {#if @deposited}
        <div class="px-2 flex flex-row items-center">
          <div class="font-bold grow">Quote:</div>
          <div class="px-2 flex flex-col">
            {#for val <- estimate}
              <div>
                {Money.to_string(val)}
              </div>
            {/for}
          </div>
        </div>
        <div class="divider -py-2" />
        <div class="px-2 flex flex-col gap-2">
          <div class="flex flex-row items-center">
            <div class="font-bold grow">Deposited:</div>
            <div class="flex flex-col">
              {#for val <- deposited}
                <div>
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
          <div class="divider -px-2" />
          <div class="flex flex-row items-center">
            <div class="font-bold grow">Remaining Balance:</div>
            <div class="flex flex-col">
              {#for val <- remaining}
                <div>
                  {Money.to_string(val)}
                </div>
              {/for}
            </div>
          </div>
        </div>
      {#else}
        <div class="px-2 flex">
          <div class="font-bold grow">Quote:</div>
          <div class="flex flex-col">
            {#for val <- estimate}
              <div>
                {Money.to_string(val)}
              </div>
            {/for}
          </div>
        </div>
      {/if}
      <div class="divider" />
      {#if @offering && Enum.any?(@offering.options)}
        <h5 class="text-xl px-2">Add-ons</h5>
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
          {#if @custom_changeset}
            <li class="flex gap-2 p-2">
              <button type="button" :on-click={@toggle_custom} class="w-8 text-xl fas fa-plus-circle" />
              <div class="grow flex flex-col">
                <div class="font-bold">Custom Option</div>
                <div class="text-sm">Add a customized option to the summary.</div>
              </div>
              <div class="p-2">TBD</div>
            </li>
          {/if}
        </ul>
        {#if @custom_changeset}
          <div
            class={"flex flex-col modal", "modal-open": @open_custom}
            :on-click={@toggle_custom}
            :on-window-keydown={@close_custom}
            phx-key="Escape"
          >
            <div :on-click={@nothing} class="modal-box relative">
              <div class="btn btn-sm btn-circle absolute right-2 top-2" :on-click={@close_custom}>✕</div>
              <Form
                class="flex flex-col gap-2"
                for={@custom_changeset}
                change={@change_custom}
                submit={@submit_custom}
              >
                <h3 class="text-xl font-bold">Add Custom Option</h3>
                <TextInput name={:name} opts={required: true, placeholder: "Some Name"} />
                <TextArea name={:description} opts={required: true, placeholder: "A custom item just for you!"} />
                <Select
                  name={:currency}
                  options={@studio.payment_currencies
                  |> Enum.map(&{:"#{Money.Currency.name(&1)} (#{Money.Currency.symbol(&1)})", &1})}
                  selected={@studio.default_currency}
                  opts={required: true}
                />
                <TextInput name={:amount} label="Price" opts={required: true} />
                <div class="modal-action">
                  <Button primary={false} click={@toggle_custom} label="Cancel" />
                  <Submit changeset={@custom_changeset} />
                </div>
              </Form>
            </div>
          </div>
        {/if}
      {/if}
    </div>
    """
  end
end
