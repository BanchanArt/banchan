defmodule BanchanWeb.Components.Form.TagsInput do
  @moduledoc """
  Tag-management component that works like an input that has array values.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, HiddenInput}

  alias Banchan.Tags
  alias BanchanWeb.Components.Icon

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop info, :string
  prop caption, :string
  prop form, :form, from_context: {Form, :form}

  data tags, :list, default: []
  data results, :list, default: []
  data menu_selected, :integer, default: nil

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    socket =
      assign(socket,
        tags: Phoenix.HTML.Form.input_value(socket.assigns.form, socket.assigns.name) || []
      )

    {:ok, socket}
  end

  def handle_event("add_selected", %{"tag" => tag}, socket) do
    socket =
      socket
      |> assign(tags: socket.assigns.tags ++ [tag], results: [], menu_selected: nil)
      |> push_event("change", %{id: socket.assigns.id <> "-wrapper"})

    {:noreply, socket}
  end

  def handle_event("handle_input", %{"key" => key, "value" => value}, socket)
      when key in ["Enter", "Tab"] and value != "" do
    tag =
      if is_nil(socket.assigns.menu_selected) do
        value
      else
        Enum.at(socket.assigns.results, socket.assigns.menu_selected).tag
      end

    socket =
      socket
      |> assign(tags: socket.assigns.tags ++ [tag], results: [], menu_selected: nil)
      |> push_event("change", %{id: socket.assigns.id <> "-wrapper"})

    {:noreply, socket}
  end

  def handle_event("handle_input", %{"key" => "Backspace", "value" => ""}, socket) do
    if Enum.empty?(socket.assigns.tags) do
      {:noreply, socket |> assign(results: [], menu_selected: nil)}
    else
      socket =
        socket
        |> assign(
          tags: socket.assigns.tags |> Enum.reverse() |> tl() |> Enum.reverse(),
          results: [],
          menu_selected: nil
        )
        |> push_event("change", %{id: socket.assigns.id <> "-wrapper"})

      {:noreply, socket}
    end
  end

  def handle_event("handle_input", %{"key" => "ArrowDown"}, socket) do
    if Enum.empty?(socket.assigns.results) do
      {:noreply, socket}
    else
      index = socket.assigns.menu_selected || -1

      {:noreply,
       socket |> assign(menu_selected: rem(index + 1, Enum.count(socket.assigns.results)))}
    end
  end

  def handle_event("handle_input", %{"key" => "ArrowUp"}, socket) do
    if Enum.empty?(socket.assigns.results) do
      {:noreply, socket}
    else
      result_len = Enum.count(socket.assigns.results)
      index = socket.assigns.menu_selected || 0
      index = rem(index - 1, result_len)

      index =
        if index < 0 do
          result_len - 1
        else
          index
        end

      {:noreply, socket |> assign(menu_selected: index)}
    end
  end

  def handle_event("handle_input", _, socket) do
    {:noreply, socket}
  end

  def handle_event("autocomplete", %{"value" => value}, socket) do
    if is_nil(value) do
      {:noreply, socket |> assign(results: [], menu_selected: nil)}
    else
      {:noreply,
       socket
       |> assign(results: Tags.list_tags(value <> "", page_size: 5), menu_selected: nil)}
    end
  end

  def handle_event("remove", %{"index" => index}, socket) do
    {index, ""} = Integer.parse(index)

    socket =
      socket
      |> assign(tags: List.delete_at(socket.assigns.tags, index))
      |> push_event("change", %{id: socket.assigns.id <> "-wrapper"})

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div id={@id <> "-wrapper"} :hook="TagsInput">
      <Field class="grid grid-cols-1 gap-1 field" name={@name}>
        {#if @show_label}
          <label for={Phoenix.HTML.Form.input_id(@form, @name) <> "_input"} class="p-0 label">
            <span class="flex flex-row items-center gap-1 label-text">
              {@label || Phoenix.Naming.humanize(@name)}
              {#if @info}
                <div class="tooltip tooltip-right" data-tip={@info}>
                  <Icon
                    name="info"
                    size="4"
                    label="tooltip"
                    class="opacity-50 hover:opacity-100 active:opacity-100"
                  />
                </div>
              {/if}
            </span>
          </label>
        {/if}
        {#if @caption}
          <div class="text-sm text-opacity-50 help text-base-content">
            {@caption}
          </div>
        {/if}
        <div class="grid grid-cols-1 gap-2">
          <ul class={
            "tags-list flex flex-row flex-wrap p-2 gap-2 border focus-within:ring ring-primary border-base-content border-opacity-20 bg-base-100 rounded-btn cursor-text",
            "input-error": !Enum.empty?(Keyword.get_values(@form.errors, @name))
          }>
            {#for {tag, index} <- Enum.with_index(@tags)}
              <li class="flex flex-row items-center max-w-full gap-1 px-2 py-1 text-xs font-semibold text-opacity-75 no-underline uppercase rounded-full cursor-default bg-opacity-10 h-fit w-fit hover:bg-opacity-20 active:bg-opacity-20 border-base-content border-opacity-10 hover:text-opacity-100 active:text-opacity-100 bg-base-content">
                <HiddenInput
                  id={Phoenix.HTML.Form.input_id(@form, @name) <> "_#{index}"}
                  name={Phoenix.HTML.Form.input_name(@form, @name) <> "[]"}
                  value={tag}
                />
                <span class="tracking-wide">{tag}</span>
                <span
                  class="text-xs opacity-50 cursor-pointer hover:opacity-100 active:opacity-100"
                  phx-value-index={index}
                  :on-click="remove"
                >✕</span>
              </li>
            {#else}
              <li>
                <HiddenInput name={Phoenix.HTML.Form.input_name(@form, @name)} value="[]" />
              </li>
            {/for}
            <li class="relative flex-1 w-8 min-w-fit">
              <input
                id={Phoenix.HTML.Form.input_id(@form, @name) <> "_input"}
                class="w-full h-full px-0 overflow-visible border-transparent border-none shadow-none input-field bg-base-100 input-sm focus:outline-none focus:border-none focus:border-transparent focus:ring-0 focus:ring-transparent"
                phx-keydown="handle_input"
                phx-update="ignore"
                data-event-target={@myself}
                phx-target={@myself}
              />
              <ol
                :if={!Enum.empty?(@results)}
                class="absolute float-left p-2 menu menu-compact rounded-box bg-base-300"
              >
                {#for {result, index} <- Enum.with_index(@results)}
                  <li><button
                      class={"p-1", active: index == @menu_selected}
                      type="button"
                      :on-click="add_selected"
                      phx-value-tag={result.tag}
                    >{result.tag}</button></li>
                {/for}
              </ol>
              <HiddenInput
                class="hidden-val"
                id={Phoenix.HTML.Form.input_id(@form, @name) <> "__hidden_val__"}
                name={Phoenix.HTML.Form.input_name(@form, @name) <> "__hidden_val__"}
                value=""
              />
            </li>
          </ul>
          <ErrorTag class="help text-error" />
        </div>
      </Field>
    </div>
    """
  end
end
