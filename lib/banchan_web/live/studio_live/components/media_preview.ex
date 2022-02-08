defmodule BanchanWeb.StudioLive.Components.MediaPreview do
  @moduledoc """
  Media previewer meant for attachments in the commission page
  """
  use BanchanWeb, :live_component

  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  prop commission, :struct, required: true
  prop studio, :struct, required: true

  data upload, :struct, default: nil

  def open(id, %Upload{} = upload) do
    send_update(__MODULE__, id: id, upload: upload)
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, socket |> assign(upload: nil)}
  end

  @impl true
  def handle_event("nothing", _, socket) do
    # This is used to prevent clicking on images from closing the preview.
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class={"modal", "modal-open": @upload} :on-click="close">
      {#if @upload}
        <div :on-window-keydown="close" phx-key="Escape">
          {#if Uploads.image?(@upload)}
            <img
              :on-click="nothing"
              alt={@upload.name}
              src={Routes.commission_attachment_path(
                Endpoint,
                :show,
                @studio.handle,
                @commission.public_id,
                @upload.key
              )}
            />
          {#else}
            <video
              :on-click="nothing"
              alt={@upload.name}
              type={@upload.type}
              controls="controls"
              src={Routes.commission_attachment_path(
                Endpoint,
                :show,
                @studio.handle,
                @commission.public_id,
                @upload.key
              )}
            />
          {/if}
        </div>
        <button
          :on-click="close"
          type="button"
          class="hover:brightness-150 absolute top-4 right-4 text-6xl"
        >×</button>
        <a
          class="hover:brightness-150 absolute top-4 left-4 text-6xl"
          href={Routes.commission_attachment_path(
            Endpoint,
            :show,
            @studio.handle,
            @commission.public_id,
            @upload.key
          )}
        >
          <i class="float-right fas fa-file-download" />
        </a>
      {/if}
    </div>
    """
  end
end
