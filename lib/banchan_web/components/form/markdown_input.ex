defmodule BanchanWeb.Components.Form.MarkdownInput do
  @moduledoc """
  Handy-dandy markdown input textarea with preview tab!
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.LiveFileInput

  prop name, :any, required: true
  prop opts, :keyword, default: []
  prop label, :string
  prop show_label, :boolean, default: true
  prop class, :css_class
  prop info, :string
  prop upload, :struct
  prop cancel_upload, :event

  data dragging, :boolean, default: false

  def update(assigns, socket) do
    val =
      Phoenix.HTML.Form.input_value(
        Map.get(assigns[:__context__], {Surface.Components.Form, :form}),
        assigns.name
      )

    {:ok, socket |> assign(assigns) |> push_event("#{assigns.id}-hook:updated", %{"value" => val})}
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
        <InputContext assigns={assigns} :let={field: field}>
          <Label class="label">
            <span class="label-text">
              {@label || Phoenix.Naming.humanize(field)}
              {#if @info}
                <div class="tooltip" data-tip={@info}>
                  <i class="fas fa-info-circle" />
                </div>
              {/if}
            </span>
          </Label>
        </InputContext>
      {/if}
      <div class="control">
        <div class="relative">
          <div
            class="h-56 rounded-lg"
            phx-update="ignore"
            phx-drop-target={@upload && @upload.ref}
            :hook="MarkdownInput"
            id={@id <> "-hook"}
          >
            <div id={@id <> "-editor"} phx-update="ignore" class="object-cover editor w-full" />
            <TextArea class="hidden input-textarea" />
          </div>
          {#if @upload}
            {#if @dragging}
              <div class="absolute h-full w-full opacity-25 bg-neutral border-dashed border-2" />
              <div class="absolute h-full w-full text-center my-auto">
                Drop Files Here <i class="fas fa-file-upload" />
              </div>
            {/if}
            <label class="absolute right-1 bottom-10 z-40">
              <i class="fas fa-file-upload text-2xl hover:cursor-pointer" />
              <LiveFileInput class="h-0 w-0 overflow-hidden" upload={@upload} />
            </label>
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
      </div>
      <ErrorTag class="help text-error" />
    </Field>
    """
  end
end
