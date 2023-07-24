defmodule BanchanWeb.Components.Form.FancySelect.Item do
  @moduledoc """
  Renderless component for dropdown items.
  """
  use BanchanWeb, :components, slot: "items"

  prop label, :string, required: true
  prop description, :string
  prop value, :any, required: true
  prop selected, :boolean, default: false
end

defmodule BanchanWeb.Components.Form.FancySelect do
  @moduledoc """
  Non-form dropdown with fancier features than Select. Meant more for things
  like dropdowns that change things and such.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Icon

  data selected, :integer, default: 0
  data highlighted, :integer, default: 0

  slot items

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    selected =
      socket.assigns.items
      |> Enum.find_index(& &1.selected)

    {:ok, socket |> assign(selected: selected, max: Enum.count(socket.assigns.items) - 1)}
  end

  def render(assigns) do
    ~F"""
    <bc-dropdown id={@id}>
      <label id={@id <> "-label"} class="sr-only">
        {@label}
        {#if Enum.count(@items) > 1}
          <Icon name="chevron-down" />
        {/if}
      </label>
      <div class="relative">
        <button
          type="button"
          class="inline-flex items-center rounded-l-none rounded-r-md bg-primary p-2 hover:bg-primary-focus focus:outline-none focus:ring-2 focus:ring-ring-primary focus:ring-offset-2 focus:ring-offset-content"
          aria-haspopup="listbox"
          aria-expanded="true"
          aria-labelledby={@id <> "-label"}
          :on-click={JS.toggle(
            to: @id <> "-options",
            out: {"transition ease-in duration-100", "opacity-100", "opacity-0"}
          )}
          :on-window-keydown={JS.hide(
            to: @id <> "-options",
            transition: {"transition ease-in duration-100", "opacity-100", "opacity-0"}
          )}
          phx-key="Escape"
        >
          <p class="text-sm font-semibold">{@label}</p>
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
          role="listbox"
          aria-labelledby={@id <> "-label"}
          aria-activedescendant={@id <> "-option-" <> "#{elem(selected, 1)}"}
          id={@id <> "-options"}
        >
          {#for {item, idx} <- @items |> Enum.with_index()}
            {!-- # TODO:
            Select option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.
            --}
            <li
              class={
                "cursor-default select-none p-4 text-sm",
                "bg-primary text-primary-content": idx == @highlighted,
                "bg-base-200 text-base-content": idx != @highlighted
              }
              id={@id <> "-option-" <> "#{idx}"}
              role="option"
            >
              <div class="flex flex-col">
                <div class="flex justify-between">
                  <p class={"font-semibold": item.selected, "font-normal": !item.selected}>{item.label}</p>
                  {!-- # TODO:
                  Checkmark, only display for selected option.

                  Highlighted: "text-white", Not Highlighted: "text-indigo-600"
                  --}
                  <span :if={@selected == idx}>
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
    </bc-dropdown>
    """
  end
end
