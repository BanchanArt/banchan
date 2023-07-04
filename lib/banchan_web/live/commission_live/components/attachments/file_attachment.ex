defmodule BanchanWeb.CommissionLive.Components.Attachments.FileAttachment do
  @moduledoc """
  Component for displaying non-image attachments listed under the other image attachment previews.
  """
  use BanchanWeb, :component

  alias Banchan.Uploads

  prop name, :string
  prop type, :string
  prop entry, :struct
  prop cancel, :event
  prop upload, :struct

  def render(assigns) do
    ~F"""
    <div class="border-2 p-2 m-1 overflow-hidden cursor-default">
      {#if @cancel && @entry}
        <button type="button" class="text-2xl" :on-click={@cancel} phx-value-ref={@entry.ref}>&times;</button>
      {/if}
      {@name || (@entry && @entry.client_name)}
      {#if @type && @type != ""}
        ({@type})
      {#elseif @entry && @entry.client_type && @entry.client_type != ""}
        ({@entry.client_type})
      {/if}
      {#if @entry && @upload}
        <progress class="progress progress-primary" value={@entry.progress} max="100">{@entry.progress}%</progress>
        {#for err <- upload_errors(@upload, @entry)}
          <p class="text-error">{Uploads.error_to_string(err)}</p>
        {/for}
      {/if}
    </div>
    """
  end
end
