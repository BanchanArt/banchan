defmodule BanchanWeb.CommissionLive.Components.Summary do
  @moduledoc """
  Summary card for the Commissions Page sidebar
  """
  use BanchanWeb, :component

  alias Surface.Components.Form

  alias BanchanWeb.Components.Collapse
  alias BanchanWeb.Components.Form.{HiddenInput, Select, Submit, TextArea, TextInput}

  prop studio, :struct
  prop line_items, :list, required: true
  prop allow_edits, :boolean, default: false
  prop show_options, :boolean, default: true
  prop offering, :struct
  prop add_item, :event
  prop remove_item, :event

  prop custom_changeset, :struct
  prop custom_collapse_id, :string
  prop submit_custom, :event
  prop change_custom, :event

  def render(assigns) do
    ~F"""
    <div class="flex flex-col">
      <ul class="flex flex-col">
        {#for {item, idx} <- Enum.with_index(@line_items)}
          <li class="flex flex-row p-2 gap-2">
            {#if @allow_edits && !item.sticky}
              <button
                type="button"
                :on-click={@remove_item}
                value={idx}
                class="text-xl w-8 fas fa-times-circle text-error"
              />
            {#else}
              <button
                type="button"
                disabled="true"
                title="This item cannot be removed"
                class="w-8 place-self-center text-xl fas fa-check"
              />
            {/if}
            <div class="grow w-full flex flex-col">
              <div class="font-medium text-sm">{item.name}</div>
              <div class="text-xs">{item.description}</div>
            </div>
            <div class="p-2 font-medium text-sm">{Money.to_string(item.amount)}</div>
          </li>
        {/for}
      </ul>
      {#if @show_options &&
          @offering &&
          Enum.any?(@offering.options, fn option ->
            option.multiple || !Enum.any?(@line_items, &(&1.option && &1.option.id == option.id))
          end)}
        <h5 class="px-2 font-medium">Add-ons:</h5>
        <ul class="flex flex-col">
          {#for {option, idx} <- Enum.with_index(@offering.options)}
            {#if option.multiple || !Enum.any?(@line_items, &(&1.option && &1.option.id == option.id))}
              <li class="flex flex-row gap-2 p-2">
                {#if @allow_edits}
                  <button
                    type="button"
                    :on-click={@add_item}
                    value={idx}
                    class="w-8 text-xl fas fa-plus-circle text-success"
                  />
                {#else}
                  <div class="w-8" />
                {/if}
                <div class="grow w-full flex flex-col">
                  <div class="font-medium text-sm">{option.name}</div>
                  <div class="text-xs">{option.description}</div>
                </div>
                <div class="p-2 text-sm font-medium">{Money.to_string(option.price)}</div>
              </li>
            {/if}
          {/for}
          {#if @custom_changeset}
            <li class="p-2 pr-4">
              <Collapse id={@custom_collapse_id}>
                <:header>
                  <div class="flex flex-row gap-2">
                    <i type="button" class="w-8 text-xl fas fa-plus-circle text-success" />
                    <div class="grow flex flex-col">
                      <div class="font-medium text-sm">Custom Option</div>
                      <div class="text-xs">Add a customized option to the summary.</div>
                    </div>
                  </div>
                </:header>
                <Form
                  class="flex flex-col gap-2"
                  for={@custom_changeset}
                  change={@change_custom}
                  submit={@submit_custom}
                >
                  <TextInput name={:name} opts={required: true, placeholder: "Some Name"} />
                  <TextArea name={:description} opts={required: true, placeholder: "A custom item just for you!"} />
                  <div class="flex flex-row gap-2 items-center py-2">
                    {#case @studio.payment_currencies}
                      {#match [_]}
                        <div class="flex flex-basis-1/4">{Money.Currency.symbol(@studio.default_currency)}</div>
                        <HiddenInput name={:currency} value={@studio.default_currency} />
                      {#match _}
                        <div class="flex-basis-1/4">
                          <Select
                            name={:currency}
                            show_label={false}
                            options={@studio.payment_currencies
                            |> Enum.map(&{Money.Currency.symbol(&1), &1})}
                            selected={@studio.default_currency}
                          />
                        </div>
                    {/case}
                    <div class="grow">
                      <TextInput name={:amount} show_label={false} opts={required: true, placeholder: "12.34"} />
                    </div>
                  </div>
                  <Submit class="w-full" changeset={@custom_changeset} />
                </Form>
              </Collapse>
            </li>
          {/if}
        </ul>
      {/if}
    </div>
    """
  end
end
