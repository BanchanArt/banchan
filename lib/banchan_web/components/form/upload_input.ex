defmodule BanchanWeb.Components.Form.UploadInput do
  @moduledoc """
  File upload input component.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveFileInput

  prop upload, :struct, required: true
  prop label, :string, default: "Upload attachments"
  prop cancel, :event, required: true
  prop class, :css_class
  prop hide_list, :boolean

  def render(assigns) do
    ~F"""
    <ul class={@class}>
      {#for entry <- @upload.entries}
        <li>
          {#if @hide_list}
            {#for err <- upload_errors(@upload, entry)}
              <p class="text-error">{entry.client_name}: {error_to_string(err)}</p>
            {/for}
          {#else}
            <button type="button" class="text-2xl" :on-click={@cancel} phx-value-ref={entry.ref}>&times;</button>
            {entry.client_name}
            <progress class="progress progress-primary" value={entry.progress} max="100">{entry.progress}%</progress>
            {#for err <- upload_errors(@upload, entry)}
              <p class="text-error">{error_to_string(err)}</p>
            {/for}
          {/if}
        </li>
      {/for}
    </ul>
    {#for err <- upload_errors(@upload)}
      <p class="text-error">{error_to_string(err)}</p>
    {/for}
    <div
      class="relative h-15 rounded-lg border-dashed border-2 border-primary flex justify-center items-center"
      phx-drop-target={@upload.ref}
    >
      <div class="absolute">
        <span class="block font-normal">{@label} <i class="fas fa-file-upload" /></span>
      </div>
      <LiveFileInput class="h-full w-full opacity-0 hover:cursor-pointer" upload={@upload} />
    </div>
    """
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
