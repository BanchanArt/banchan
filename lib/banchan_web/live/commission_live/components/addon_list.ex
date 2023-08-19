defmodule BanchanWeb.CommissionLive.Components.AddonList do
  @moduledoc """
  Plain component for displaying a list of addons.
  """
  use BanchanWeb, :component

  alias Banchan.Commissions
  alias Banchan.Offerings
  alias Banchan.Payments

  alias Surface.Components.Form

  alias BanchanWeb.Components.{Collapse, Icon}
  alias BanchanWeb.Components.Form.{Submit, TextArea, TextInput}

  prop commission, :struct, from_context: :commission

  prop offering, :struct
  prop line_items, :list, required: true
  prop add_item, :event
  prop custom_changeset, :struct
  prop id, :string, required: true
  prop submit_custom, :event
  prop change_custom, :event
  prop allow_edits, :boolean, default: false

  def set_open_custom(id, open?) do
    Collapse.set_open(id <> "-custom-collapse", open?)
  end

  def render(assigns) do
    ~F"""
    <bc-addon-list>
      <ul class="flex flex-col items-start w-full gap-4">
        {#for {option, idx} <- Enum.with_index(@offering.options)}
          {#if !Enum.any?(@line_items, &(&1.option && &1.option.id == option.id))}
            <li class="flex flex-row items-center w-full gap-4">
              {#if @allow_edits && @add_item}
                <button
                  type="button"
                  class="w-8 text-xl opacity-50 hover:text-success hover:opacity-100"
                  :on-click={@add_item}
                  value={idx}
                >
                  <Icon name="plus-circle" />
                </button>
              {#else}
                <Icon name="check-circle-2" class="w-8 text-xl opacity-50" />
              {/if}
              <div class="flex flex-col w-full grow">
                <div class="text-sm font-medium">{option.name}</div>
                <div class="text-xs opacity-75">{option.description}</div>
              </div>
              <div class="text-sm font-medium whitespace-nowrap">+{Payments.print_money(option.price)}</div>
            </li>
          {/if}
        {/for}
        {#if @custom_changeset && @allow_edits}
          <li class="w-full">
            <Collapse id={@id <> "-custom-collapse"}>
              <:header>
                <div class="flex flex-row items-center w-full gap-4">
                  <Icon name="plus-circle" class="text-xl opacity-50 hover:text-success" />
                  <div class="flex flex-col w-full grow">
                    <div class="text-sm font-medium">Custom Option</div>
                    <div class="text-xs opacity-75">Add a customized option to the summary.</div>
                  </div>
                </div>
              </:header>
              <Form
                class="flex flex-col w-full gap-2"
                for={@custom_changeset}
                change={@change_custom}
                submit={@submit_custom}
              >
                <TextInput name={:name} opts={required: true, placeholder: "Some Name"} />
                <TextArea name={:description} opts={required: true, placeholder: "A custom item just for you!"} />
                <div class="flex flex-row items-center gap-2 py-2">
                  <div class="flex flex-basis-1/4">{if is_nil(@offering) do
                      Payments.currency_symbol(Commissions.commission_currency(@commission))
                    else
                      Payments.currency_symbol(Offerings.offering_currency(@offering))
                    end}</div>
                  <div class="grow">
                    <TextInput name={:amount} show_label={false} opts={required: true} />
                  </div>
                </div>
                <Submit class="w-full" changeset={@custom_changeset} />
              </Form>
            </Collapse>
          </li>
        {/if}
      </ul>
    </bc-addon-list>
    """
  end
end
