defmodule BanchanWeb.Components.Form.TagsInput do
  @moduledoc """
  Tag-management component that works like an input that has array values.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form.{ErrorTag, Field, HiddenInput}
  alias Surface.Components.Form.Input.InputContext

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop class, :css_class
  prop label, :string
  prop show_label, :boolean, default: true
  prop info, :string

  data tags, :list, default: []

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    form = Map.get(socket.assigns.__context__, {Surface.Components.Form, :form})
    socket = assign(socket, tags: Phoenix.HTML.Form.input_value(form, socket.assigns.name))
    {:ok, socket}
  end

  def handle_event("keydown", %{"key" => key, "value" => value}, socket) do
    cond do
      key in ["Enter", "Tab", " "] ->
        socket =
          socket
          |> assign(tags: socket.assigns.tags ++ [value])
          |> push_event("change", %{})

        {:noreply, socket}

      key == "Backspace" && value == "" && !Enum.empty?(socket.assigns.tags) ->
        socket =
          socket
          |> assign(tags: socket.assigns.tags |> Enum.reverse() |> tl() |> Enum.reverse())
          |> push_event("change", %{})

        {:noreply, socket}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("remove", %{"tag" => tag}, socket) do
    socket =
      socket
      |> assign(tags: socket.assigns.tags |> Enum.filter(&(&1 != tag)))
      |> push_event("change", %{})

    {:noreply, socket}
  end

  def handle_event("nothing", _, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      {#if @show_label}
        <InputContext assigns={assigns} :let={form: form, field: field}>
          <label for={Phoenix.HTML.Form.input_id(form, field) <> "_input"} class="label">
            <span class="label-text">
              {@label || Phoenix.Naming.humanize(field)}
              {#if @info}
                <div class="tooltip" data-tip={@info}>
                  <i class="fas fa-info-circle" />
                </div>
              {/if}
            </span>
          </label>
        </InputContext>
      {/if}
      <div id={@id <> "_container"} :hook="TagsInput" class="flex flex-col">
        <InputContext :let={form: form, field: field}>
          <ul class={
            "flex flex-row flex-wrap p-1 gap-1 border shadow focus-within:ring items-center justify-center border-base-content border-opacity-20 bg-base-100 rounded-btn",
            "input-error": !Enum.empty?(Keyword.get_values(form.errors, field))
          }>
            {#for {tag, index} <- Enum.with_index(@tags)}
              <li class="badge badge-lg badge-primary gap-2">
                <HiddenInput
                  id={Phoenix.HTML.Form.input_id(form, field) <> "_#{index}"}
                  name={Phoenix.HTML.Form.input_name(form, field) <> "[]"}
                  value={tag}
                />
                <span class="hover:cursor-pointer text-xs" phx-value-tag={tag} :on-click="remove">✕</span><span>
                  #{tag}</span>
              </li>
            {#else}
              <li>
                <HiddenInput name={Phoenix.HTML.Form.input_name(form, field)} value="[]" />
              </li>
            {/for}
            <li class="flex-1">
              <input
                id={Phoenix.HTML.Form.input_id(form, field) <> "_input"}
                type="text"
                class="input-field bg-base-100 input-sm w-full h-full min-w-10 focus:outline-none border-none focus:border-none border-transparent focus:border-transparent shadow-none focus:ring-0 focus:ring-transparent overflow-visible"
                phx-change="nothing"
                phx-keydown="keydown"
                phx-target={@myself}
              />
              <HiddenInput
                class="hidden-val"
                id={Phoenix.HTML.Form.input_id(form, field) <> "__hidden_val__"}
                name={Phoenix.HTML.Form.input_name(form, field) <> "__hidden_val__"}
                value=""
              />
            </li>
          </ul>
        </InputContext>
        <ErrorTag class="help text-error" />
      </div>
    </Field>
    """
  end
end
