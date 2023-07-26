defmodule BanchanWeb.Components.Form.FancySelect.Item do
  @moduledoc """
  Renderless component for dropdown items.
  """
  use BanchanWeb, type: :component, slot: "items"

  prop label, :string, required: true
  prop description, :string
  prop value, :any, required: true
end

defmodule BanchanWeb.Components.Form.FancySelect do
  @moduledoc """
  Non-form dropdown with fancier features than Select. Meant more for things
  like dropdowns that change things and such.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  # alias Surface.Components.Form.{ErrorTag, Field, HiddenInput, Label}

  alias BanchanWeb.Components.Icon

  prop name, :any, required: true
  prop label, :string
  prop show_label, :boolean, default: true
  prop form, :form, from_context: {Form, :form}

  data selected, :struct
  data selected_idx, :integer, default: 0

  slot items

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    {:ok,
     socket
     |> assign(
       max: Enum.count(socket.assigns.items) - 1,
       selected: Enum.at(socket.assigns.items, socket.assigns.selected_idx)
     )}
  end

  def handle_event("selected", %{"selected" => selected_idx}, socket) do
    {:noreply,
     socket
     |> assign(selected_idx: selected_idx, selected: Enum.at(socket.assigns.items, selected_idx))}
  end

  def render(assigns) do
    ~F"""
    <bc-fancy-select id={@id} :hook="FancySelect">
      <label id={@id <> "-label"} class="sr-only">
        {@selected.label}
        {#if Enum.count(@items) > 1}
          <Icon name="chevron-down" />
        {/if}
      </label>
      <div class="relative">
        <button
          type="button"
          class="inline-flex w-full items-center rounded-md bg-primary p-2 hover:bg-primary-focus focus:outline-none focus:ring-2 focus:ring-ring-primary focus:ring-offset-2 focus:ring-offset-content"
          aria-haspopup="listbox"
          aria-expanded="true"
          aria-labelledby={@id <> "-label"}
          :on-window-keydown={JS.hide(
            to: @id <> "-options",
            transition: {"transition ease-in duration-100", "opacity-100", "opacity-0"}
          )}
          phx-key="Escape"
        >
          <p class="text-sm font-semibold text-primary-content">{@selected.label}</p>
        </button>
        {!-- # TODO:
      Select popover, show/hide based on select state.

      Entering: ""
        From: ""
        To: ""
      Leaving: "transition ease-in duration-100"
        From: "opacity-100"
        To: "opacity-0"
      --}
        <ul
          class="absolute right-0 z-10 mt-2 w-72 origin-top-right divide-y divide-neutral overflow-hidden rounded-md bg-base-200 shadow-lg ring-1 ring-base-300 ring-opacity-5 focus:outline-none"
          tabindex="-1"
          style="display: none;"
          role="listbox"
          aria-labelledby={@id <> "-label"}
          aria-activedescendant={@id <> "-option-" <> "#{@selected_idx}"}
          id={@id <> "-options"}
        >
          {#for {item, idx} <- @items |> Enum.with_index()}
            {!-- # TODO:
            Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.
            --}
            <li
              class="cursor-default select-none p-4 text-sm"
              id={@id <> "-option-" <> "#{idx}"}
              role="option"
            >
              <div class="flex flex-col">
                <div class="flex justify-between">
                  <p class={"font-semibold": idx == @selected_idx, "font-normal": idx != @selected_idx}>{item.label}</p>
                  {!-- # TODO:
                  Checkmark, only display for selected option.

                  Highlighted: "text-white", Not Highlighted: "text-indigo-600"
                  --}
                  <span :if={@selected_idx == idx}>
                    <Icon name="check" />
                  </span>
                </div>
                {!-- # TODO: Highlighted: "text-indigo-200", Not Highlighted: "text-gray-500" --}
                <p class="mt-2">{item.description}</p>
              </div>
            </li>
          {/for}
        </ul>
      </div>
    </bc-fancy-select>
    """
  end
end
