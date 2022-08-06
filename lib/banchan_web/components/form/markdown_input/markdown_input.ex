defmodule BanchanWeb.Components.Form.MarkdownInput do
  @moduledoc """
  Handy-dandy markdown input textarea with preview tab!
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form.{ErrorTag, Field, Label, TextArea}
  alias Surface.Components.Form.Input.InputContext
  alias Surface.Components.LiveFileInput

  prop name, :any, required: true
  prop height, :string, default: "224px"
  prop opts, :keyword, default: []
  prop label, :string
  prop show_label, :boolean, default: true
  prop class, :css_class
  prop info, :string
  prop upload, :struct
  prop cancel_upload, :event

  data dragging, :boolean, default: false

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    val =
      Phoenix.HTML.Form.input_value(
        Map.get(assigns[:__context__], {Surface.Components.Form, :form}),
        assigns.name
      )

    if !val || val == "" do
      {:ok,
       socket
       |> push_event("clear-markdown-input", %{id: socket.assigns.id <> "-hook"})}
    else
      # NB(@zkat): See comment in hook for why we can't do this.
      # {:ok,
      #  socket
      #  |> push_event("markdown-input-updated", %{id: socket.assigns.id <> "-hook", value: val || ""})}

      {:ok, socket}
    end
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
            class={@class}
            phx-update="ignore"
            phx-drop-target={@upload && @upload.ref}
            :hook="MarkdownInput"
            id={@id <> "-hook"}
          >
            <div
              id={@id <> "-editor"}
              data-height={@height}
              phx-update="ignore"
              class="object-cover editor w-full h-full"
            />
            <TextArea class="hidden input-textarea" opts={@opts} />
          </div>
          {#if @upload}
            {#if @dragging}
              <div class="absolute h-full w-full opacity-25 bg-neutral border-dashed border-2" />
              <div class="absolute h-full w-full text-center my-auto">
                Drop Files Here <i class="fas fa-file-upload" />
              </div>
            {/if}
            <label class="absolute right-2 top-36 z-30">
              <i class="fas fa-file-upload text-2xl hover:cursor-pointer" />
              <LiveFileInput class="hidden overflow-hidden" upload={@upload} />
            </label>
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
