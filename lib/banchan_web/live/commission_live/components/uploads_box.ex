defmodule BanchanWeb.CommissionLive.Components.UploadsBox do
  @moduledoc """
  Component for rendering the latest submitted draft on the commission page
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Uploads

  alias BanchanWeb.CommissionLive.Components.{AttachmentBox, MediaPreview}
  alias BanchanWeb.Components.Collapse

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true

  data attachments, :list
  data loaded, :boolean, default: false
  data previewing, :struct, default: nil

  def update(assigns, socket) do
    current_comm = Map.get(socket.assigns, :commission)
    new_comm = Map.get(assigns, :commission)

    if socket.assigns.loaded &&
         current_comm &&
         new_comm &&
         current_comm.public_id == new_comm.public_id do
      socket = socket |> assign(assigns)
      {:ok, socket}
    else
      socket =
        if current_comm && (!new_comm || current_comm.public_id != new_comm.public_id) do
          socket |> assign(loaded: false)
        else
          socket
        end

      socket = socket |> assign(assigns)

      attachments = Commissions.list_attachments(socket.assigns.commission)

      {:ok, socket |> assign(attachments: attachments, loaded: true)}
    end
  end

  @impl true
  def handle_event("open_preview", %{"key" => key, "bucket" => bucket}, socket) do
    if socket.assigns.current_user.id == socket.assigns.commission.client_id ||
         socket.assigns.current_user_member? do
      MediaPreview.open(
        "draft-preview",
        Uploads.get_upload!(bucket, key)
      )
    end

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div>
      <Collapse id={@id <> "-uploads-box"}>
        <:header>
          <div class="text-lg font-medium">Uploads ({Enum.count(@attachments)})</div>
        </:header>
        <AttachmentBox commission={@commission} attachments={@attachments} open_preview="open_preview" />
      </Collapse>
      <MediaPreview id="draft-preview" commission={@commission} />
    </div>
    """
  end
end
