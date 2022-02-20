defmodule BanchanWeb.StudioLive.Components.Commissions.DraftBox do
  @moduledoc """
  Component for rendering the latest submitted draft on the commission page
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Uploads

  alias BanchanWeb.StudioLive.Components.Commissions.{AttachmentBox, MediaPreview}

  prop commission, :struct, required: true
  prop studio, :struct, required: true

  data attachments, :list
  data previewing, :struct, default: nil

  def update(assigns, socket) do
    socket = socket |> assign(assigns)
    event = Commissions.latest_draft(socket.assigns.commission)
    {:ok, socket |> assign(attachments: event && event.attachments)}
  end

  @impl true
  def handle_event("open_preview", %{"key" => key, "bucket" => bucket}, socket) do
    MediaPreview.open(
      "draft-preview",
      Uploads.get_upload!(bucket, key)
    )

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div>
      {#if @attachments && !Enum.empty?(@attachments)}
          <h3 class="px-2 pb-2 text-xl">Latest Draft</h3>
          <MediaPreview id="draft-preview" commission={@commission} studio={@studio} />
          <AttachmentBox
            commission={@commission}
            studio={@studio}
            attachments={@attachments}
            open_preview="open_preview"
          />
      {/if}
    </div>
    """
  end
end
