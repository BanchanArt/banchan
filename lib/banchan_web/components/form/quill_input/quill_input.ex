defmodule BanchanWeb.Components.Form.QuillInput do
  @moduledoc """
  quill.js-based rich text editor.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.LiveFileInput

  prop(name, :any, required: true)
  prop(form, :form, from_context: {Surface.Components.Form, :form})
  prop(opts, :keyword, default: [])
  # TODO: couldn't get this to work, for some reason.
  # prop height, :string, default: "224px"
  prop(label, :string)
  prop(show_label, :boolean, default: true)
  prop(class, :css_class)
  prop(info, :string)
  prop(upload, :struct)
  prop(cancel_upload, :event)

  data(dragging, :boolean, default: false)

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
      min-height: 224px;
      }
      .control :global(.ql-toolbar):global(.ql-snow) {
      @apply rounded-t-xl;
      --tw-border-opacity: 0.2;
      border: 1px solid hsl(var(--bc) / var(--tw-border-opacity));
      }
      .control :global(.ql-container) {
      @apply rounded-t-none textarea textarea-bordered;
      }
      .control .has_upload :global(.ql-container) {
      @apply rounded-b-none;
      }
      .control :global(.ql-stroke) {
      --tw-text-opacity: 1;
      stroke: hsl(var(--nc) / var(--tw-text-opacity));
      }
      .control :global(.ql-fill) {
      --tw-text-opacity: 0.8;
      fill: hsl(var(--nc) / var(--tw-text-opacity));
      }
      .control :global(.ql-picker):global(.ql-expanded) :global(.ql-picker-label) {
      @apply rounded-md;
      --tw-border-opacity: 0.2;
      border: 1px solid hsl(var(--bc) / var(--tw-border-opacity));
      }
      .control :global(.ql-picker-label) {
      color: hsl(var(--nc));
      }
      /*
      .control :global(.ql-picker) :global(.ql-picker-options) {
      @apply menu rounded-box
      }
      */
    </style>
    <Field class="field" name={@name}>
      {#if @show_label}
        <Label class="label">
          <span class="label-text">
            {@label || Phoenix.Naming.humanize(@name)}
            {#if @info}
              <div class="tooltip" data-tip={@info}>
                <i class="fas fa-info-circle" />
              </div>
            {/if}
          </span>
        </Label>
      {/if}
      <div class="control">
        <div class={"relative", "has-upload": !is_nil(@upload)}>
          <div
            class={@class}
            phx-drop-target={@upload && @upload.ref}
            phx-update="ignore"
            :hook="QuillInput"
            id={@id <> "-hook"}
          >
            <div id={@id <> "-editor"} phx-update="ignore" class="object-cover editor h-full w-full" />
            <TextArea class="hidden input-textarea" opts={@opts} />
          </div>
          {#if @upload}
            <LiveFileInput
              class="file-input file-input-xs w-full file-input-bordered rounded-t-none"
              upload={@upload}
            />
            {#if @dragging}
              <div class="absolute h-full w-full opacity-25 bg-neutral border-dashed border-2" />
              <div class="absolute h-full w-full text-center my-auto">
                Drop Files Here <i class="fas fa-file-upload" />
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
