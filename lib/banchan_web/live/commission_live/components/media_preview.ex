defmodule BanchanWeb.CommissionLive.Components.MediaPreview do
  @moduledoc """
  Media previewer meant for attachments in the commission page
  """
  use BanchanWeb, :live_component

  alias Banchan.Uploads
  alias Banchan.Uploads.Upload

  alias Surface.Components.LiveRedirect

  prop commission, :struct, required: true

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
        {!-- # TODO: Fix alignment --}
        <div class="max-w-fit max-h-fit m-10" :on-window-keydown="close" phx-key="Escape">
          {#if Uploads.image?(@upload)}
            <img
              :on-click="nothing"
              alt={@upload.name}
              src={Routes.commission_attachment_path(
                Endpoint,
                :show,
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
        <LiveRedirect
          class="hover:brightness-150 absolute top-4 left-4 text-6xl"
          to={Routes.commission_attachment_path(
            Endpoint,
            :show,
            @commission.public_id,
            @upload.key
          )}
        >
          <i class="float-right fas fa-file-download" />
        </LiveRedirect>
      {/if}
    </div>
    """
  end
end
