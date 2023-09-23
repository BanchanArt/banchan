defmodule BanchanWeb.Components.Form.QuillInput do
  @moduledoc """
  quill.js-based rich text editor.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.Icon
  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.LiveFileInput

  prop(name, :any, required: true)
  prop(opts, :keyword, default: [])
  prop(form, :form, from_context: {Form, :form})
  # TODO: couldn't get this to work, for some reason.
  # prop height, :string, default: "224px"
  prop(label, :string)
  prop(show_label, :boolean, default: true)
  prop(class, :css_class)
  prop(info, :string)
  prop(caption, :string)
  prop(upload, :struct)
  prop(cancel_upload, :event)

  data(dragging, :boolean, default: false)

  def update(assigns, socket) do
    {:ok, assign(socket, assigns) |> push_event("set_rich_text", %{id: assigns.id <> "_hook"})}
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
    <style>
      .field {
      @apply max-h-full;
      }
      .control :global(.ql-editor) {
      /* TODO: Try and get this to work? idk why the variable isn't getting defined.
      min-height: s-bind("@height")
      */
      @apply prose max-w-none p-0;
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
      min-height: 224px;
      }
      .control :global(.ql-toolbar):global(.ql-snow) {
      @apply rounded-t-xl;
      --tw-border-opacity: 0.2;
      border: 1px solid hsl(var(--bc) / var(--tw-border-opacity));
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, "Noto Sans", sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji";
      }
      .control :global(.ql-container) {
      @apply rounded-t-none textarea textarea-bordered;
      }
      .control .has-upload :global(.ql-container) {
      @apply rounded-b-none;
      }
      .control :global(.ql-stroke) {
      --tw-text-opacity: 1;
      stroke: hsl(var(--n) / var(--tw-text-opacity));
      }
      .control :global(.ql-fill) {
      --tw-text-opacity: 0.8;
      fill: hsl(var(--n) / var(--tw-text-opacity));
      }
      .control :global(.ql-picker):global(.ql-expanded) :global(.ql-picker-label) {
      @apply rounded-md;
      --tw-border-opacity: 0.2;
      border: 1px solid hsl(var(--b) / var(--tw-border-opacity));
      }
      .control :global(.ql-picker-label) {
      color: hsl(var(--n));
      }
      /*
      .control :global(.ql-editor) :global(p) {
      @apply py-2;
      }
      */
      /*
      .control :global(.ql-picker) :global(.ql-picker-options) {
      @apply menu rounded-box
      }
      */
    </style>
    <Field class="grid grid-cols-1 gap-1 field" name={@name}>
      {#if @show_label}
        <Label class="p-0 label">
          <span class="flex flex-row items-center gap-1 label-text">
            {@label || Phoenix.Naming.humanize(@name)}
            {!--
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
            --}
          </span>
        </Label>
      {/if}
      {#if @caption}
        <div class="text-sm text-opacity-50 help text-base-content">
          {@caption}
        </div>
      {/if}
      <div class="control">
        <div class={"relative", "has-upload": !is_nil(@upload)}>
          <TextArea form={@form} field={@name} class="hidden input-textarea" opts={@opts} />
          <div
            class={@class}
            phx-drop-target={@upload && @upload.ref}
            phx-update="ignore"
            :hook="QuillInput"
            id={@id <> "_hook"}
          >
            <div id={@id <> "-editor"} phx-update="ignore" class="object-cover w-full h-full editor" />
          </div>
          {#if @upload}
            <LiveFileInput
              class="w-full text-sm rounded-t-none file-input file-input-bordered"
              upload={@upload}
            />
            {#if @dragging}
              <div class="absolute w-full h-full border-2 border-dashed opacity-25 bg-neutral" />
              <div class="absolute w-full h-full my-auto text-center">
                Drop Files Here <Icon name="file-up" size="4" label="upload file" />
              </div>
            {/if}
          {/if}
        </div>
      </div>
      <ErrorTag class="help text-error" />
      {#if @upload}
        <ul>
          {#for entry <- @upload.entries}
            <li>
              <button type="button" class="text-2xl" :on-click={@cancel_upload} phx-value-ref={entry.ref}>&times;</button>
              {entry.client_name}
              <progress class="progress progress-primary" value={entry.progress} max="100">{entry.progress}%</progress>
              {#for err <- upload_errors(@upload, entry)}
                <p class="text-error">{error_to_string(err)}</p>
              {/for}
            </li>
          {/for}
        </ul>
        {#for err <- upload_errors(@upload)}
          <p class="text-error">{error_to_string(err)}</p>
        {/for}
      {/if}
    </Field>
    """
  end
end
