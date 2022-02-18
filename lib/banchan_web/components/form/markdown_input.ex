defmodule BanchanWeb.Components.Form.MarkdownInput do
  @moduledoc """
  Handy-dandy markdown input textarea with preview tab!
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.Form.Input.InputContext

  alias BanchanWeb.Components.Markdown

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop label, :string
  prop show_label, :boolean, default: true
  prop class, :css_class
  prop hook_id, :string, default: "markdown-input-wrapper-id"

  data previewing, :boolean, default: false
  data markdown, :string, default: ""

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(markdown: "")}
  end

  @impl true
  def handle_event("markdown", _, socket) do
    {:noreply, assign(socket, previewing: false)}
  end

  def handle_event("preview", _, socket) do
    {:noreply, assign(socket, previewing: true)}
  end

  def handle_event("change", %{"value" => markdown}, socket) do
    {:noreply, assign(socket, markdown: markdown || "")}
  end

  def render(assigns) do
    ~F"""
    <Field class="field" name={@name}>
      {#if @show_label}
        {#if @label}
          <Label class="label">
            {@label}
          </Label>
        {#else}
          <Label class="label" />
        {/if}
      {/if}
      <div class="control">
        <InputContext :let={form: form, field: field}>
          <div class="tabs flex flex-nowrap">
            <a :on-click="markdown" class={"tab tab-lifted flex-1 tab-lg", "tab-active": !@previewing}>Write</a>
            <a :on-click="preview" class={"tab tab-lifted flex-1 tab-lg", "tab-active": @previewing}>Preview</a>
          </div>
          <div>
            {#if @previewing}
              <div class="h-40 border-2 overflow-auto border-neutral rounded">
                <div class="p-2 text-sm">
                  {#if @markdown == ""}
                    Nothing to preview
                  {#else}
                    <Markdown content={@markdown} />
                  {/if}
                </div>
              </div>
            {#else}
              <div :hook="MarkdownInput" id={@hook_id}>
                <TextArea
                  class={
                    "textarea",
                    "textarea-bordered",
                    "textarea-primary",
                    "h-40",
                    @class,
                    "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
                  }
                  opts={@opts}
                />
              </div>
            {/if}
          </div>
        </InputContext>
      </div>
      <ErrorTag class="help is-danger" />
    </Field>
    """
  end
end
