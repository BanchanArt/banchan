defmodule BanchanWeb.Components.Form.MarkdownInput do
  @moduledoc """
  Handy-dandy markdown input textarea with preview tab!
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.LiveFileInput

  alias BanchanWeb.Components.Markdown

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop label, :string
  prop show_label, :boolean, default: true
  prop class, :css_class
  prop hook_id, :string, default: "markdown-input-wrapper-id"
  prop upload, :struct
  prop cancel_upload, :event

  data dragging, :boolean, default: false
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

  def handle_event("dragstart", _, socket) do
    {:noreply, assign(socket, dragging: true)}
  end

  def handle_event("dragend", _, socket) do
    {:noreply, assign(socket, dragging: false)}
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

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
              <div
                class="relative flex h-40 w-full"
                phx-drop-target={@upload && @upload.ref}
                :hook="MarkdownInput"
                id={@hook_id}
              >
                <TextArea
                  class={
                    "textarea",
                    "textarea-bordered",
                    "h-40",
                    "w-full",
                    @class,
                    "textarea-error": !Enum.empty?(Keyword.get_values(form.errors, field))
                  }
                  opts={@opts}
                />
                {#if @upload}
                  {#if @dragging}
                    <div class="absolute h-full w-full opacity-25 bg-neutral border-dashed border-2" />
                    <div class="absolute h-full w-full text-center my-auto">
                      Drop Files Here <i class="fas fa-file-upload" />
                    </div>
                  {/if}
                  <label class="absolute right-2 bottom-2">
                    <i class="fas fa-file-upload text-2xl hover:cursor-pointer" />
                    <LiveFileInput class="h-0 w-0 overflow-hidden" upload={@upload} />
                  </label>
                {/if}
              </div>
            {/if}
            {#if @upload}
              <ul>
                {#for entry <- @upload.entries}
                  <li>
                    <button type="button" class="text-2xl" :on-click={@cancel_upload} phx-value-ref={entry.ref}>&times;</button>
                    {entry.client_name}
                    <progress class="progress progress-primary" value={entry.progress} max="100">{entry.progress}%</progress>
                    {#for err <- upload_errors(@upload, entry)}
                      <p>{error_to_string(err)}</p>
                    {/for}
                  </li>
                {/for}
              </ul>
              {#for err <- upload_errors(@upload)}
                <p>{error_to_string(err)}</p>
              {/for}
            {/if}
          </div>
        </InputContext>
      </div>
      <ErrorTag class="help text-error" />
    </Field>
    """
  end
end
