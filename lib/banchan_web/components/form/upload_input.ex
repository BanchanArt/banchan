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
    <LiveFileInput upload={@upload} />
    <ul>
      {#for entry <- @upload.entries}
        <li>{entry.client_name}
        <button :on-click={@cancel} phx-value-ref={entry.ref}>&times;</button>
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
    """
  end

  def error_to_string(:too_large), do: "Too large"
  def error_to_string(:too_many_files), do: "You have selected too many files"
  def error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
