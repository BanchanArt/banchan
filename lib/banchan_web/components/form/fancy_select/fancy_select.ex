defmodule BanchanWeb.Components.Form.FancySelect.Item do
  @moduledoc """
  Renderless component for dropdown items.
  """
  use BanchanWeb, type: :component, slot: "default"

  prop(label, :string, required: true)
  prop(description, :string)
  prop(value, :any, required: true)
end

defmodule BanchanWeb.Components.Form.FancySelect do
  @moduledoc """
  Non-form dropdown with fancier features than Select. Meant more for things
  like dropdowns that change things and such.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, HiddenInput, Label}

  alias BanchanWeb.Components.Icon

  prop(name, :any, required: true)
  prop(label, :string)
  prop(class, :css_class)
  prop(show_label, :boolean, default: true)
  prop(show_chevron, :boolean, default: true)
  prop(disabled, :boolean, default: false)
  prop(form, :form, from_context: {Form, :form})
  prop(items, :list, default: [])

  data(selected, :struct)
  data(selected_idx, :integer, default: 0)

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    if is_nil(assigns.form) do
      {:ok, socket}
    else
      {selected_idx, ""} = Map.get(assigns.form.params, "#{assigns.name}", "0") |> Integer.parse()

      {:ok,
       socket
       |> assign(
         max: Enum.count(socket.assigns.items) - 1,
         selected_idx: selected_idx,
         selected: Enum.at(socket.assigns.items, selected_idx)
       )}
    end
  end

  def render(assigns) do
    ~F"""
    <bc-fancy-select id={@id} :hook="FancySelect">
      <Field class="grid grid-cols-1 gap-2 field" name={@name}>
        <Label class="sr-only" opts={id: @id <> "-label"}>
          {@selected.label}
        </Label>
        <HiddenInput name={@name} />
        <div class="relative">
          <button
            disabled={@disabled}
            type="button"
            class={# "inline-flex items-center rounded-md bg-primary p-2 hover:bg-primary-focus focus:outline-none focus:ring-2 focus:ring-ring-primary focus:ring-offset-2 focus:ring-offset-content",
            @class}
            aria-haspopup="listbox"
            aria-expanded="true"
            aria-labelledby={@id <> "-label"}
          >
            <p class="text-sm font-semibold text-primary-content">{@selected.label}</p>
            {#if @show_chevron}
              <Icon name="chevron-down" />
            {/if}
          </button>
          <ul
            class="absolute left-0 z-30 mt-2 overflow-hidden origin-top-right border divide-y w-72 divide-neutral divide-opacity-50 rounded-box bg-base-200 border-base-content border-opacity-10 focus:outline-none"
            tabindex="-1"
            style="display: none;"
            role="listbox"
            aria-labelledby={@id <> "-label"}
            aria-activedescendant={@id <> "-option-" <> "#{@selected_idx}"}
            id={@id <> "-options"}
          >
            {#for {item, idx} <- @items |> Enum.with_index()}
              <li
                class="p-4 text-sm cursor-pointer select-none"
                id={@id <> "-option-" <> "#{idx}"}
                role="option"
              >
                <div class="grid grid-cols-1 gap-2">
                  <div class="flex justify-between">
                    <p class={"font-semibold": idx == @selected_idx, "font-normal": idx != @selected_idx}>{item.label}</p>
                    <span :if={@selected_idx == idx}>
                      <Icon name="check" class="text-primary" />
                    </span>
                  </div>
                  <p class="mt-2 opacity-75">{item.description}</p>
                </div>
              </li>
            {/for}
          </ul>
        </div>
        <ErrorTag class="help text-error" />
      </Field>
    </bc-fancy-select>
    """
  end
end
