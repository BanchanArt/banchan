defmodule BanchanWeb.StudioLive.Components.AttachmentInput do
  @moduledoc """
  File upload input component.
  """
  use BanchanWeb, :component

  alias Surface.Components.LiveFileInput

  prop upload, :struct, required: true
  prop completed, :list, required: true

  def render(assigns) do
    ~F"""
    <LiveFileInput upload={@upload} />
    <ul>
      {#for completed <- @completed}
        <li>{completed.name} uploaded</li>
      {/for}
      {#for entry <- @upload.entries}
        <li>{entry.client_name}</li>
        <progress value={entry.progress} max="100">{entry.progress}%</progress>
        {#for err <- upload_errors(@upload, entry)}
          <p>{error_to_string(err)}</p>
        {/for}
      {/for}
    </ul>
    {#for err <- upload_errors(@upload)}
      <p>{error_to_string(err)}</p>
    {/for}
    """
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
end
