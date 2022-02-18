defmodule BanchanWeb.Components.Form.UploadInput do
  @moduledoc """
  File upload input component.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveFileInput

  prop upload, :struct, required: true
  prop cancel, :event, required: true

  def render(assigns) do
    ~F"""
    <ul>
      {#for entry <- @upload.entries}
        <li>
          <button type="button" class="text-2xl" :on-click={@cancel} phx-value-ref={entry.ref}>&times;</button>
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
    <div
      class="relative h-15 rounded-lg border-dashed border-2 border-primary flex justify-center items-center"
      phx-drop-target={@upload.ref}
    >
      <div class="absolute">
        <span class="block font-normal">Upload attachments. <i class="fas fa-file-upload" /></span>
      </div>
      <LiveFileInput class="h-full w-full opacity-0 hover:cursor-pointer" upload={@upload} />
    </div>
    """
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
