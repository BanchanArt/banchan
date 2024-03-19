defmodule BanchanWeb.WorkLive.Components.WorkUploads do
  @moduledoc """
  Displays and optionally allows editing of uploads associated with a work.
  """
  use BanchanWeb, :live_component

  alias Banchan.Uploads

  alias BanchanWeb.Components.{
    Icon,
    Lightbox
  }

  prop editing, :boolean, default: false
  prop work_uploads, :list, required: true
  prop live_entries, :any, required: true
  prop studio, :struct, required: true
  prop work, :struct, required: true
  prop can_download?, :boolean, required: true
  prop send_updates_to, :any
  prop class, :css_class

  def update(assigns, socket) do
    old_assigns = socket.assigns
    socket = socket |> assign(assigns)

    if !is_nil(old_assigns[:live_entries]) && assigns[:live_entries] != old_assigns[:live_entries] do
      uploads =
        assigns.work_uploads
        |> Enum.filter(fn {type, data} ->
          if type == :live do
            # Keep only if it exists in the new uploads list.
            Enum.find(assigns[:live_entries], &(&1.ref == data.ref))
          else
            true
          end
        end)

      new_uploads =
        assigns[:live_entries]
        |> Enum.filter(fn entry ->
          !Enum.find(assigns.work_uploads, fn {type, data} ->
            type == :live && data.ref == entry.ref
          end)
        end)
        |> Enum.map(&{:live, &1})

      new_uploads = uploads ++ new_uploads

      notify_changed(new_uploads, socket)
    end

    {:ok, socket}
  end

  defp notify_changed(_, %{assigns: %{send_updates_to: nil}}) do
    nil
  end

  defp notify_changed(images, %{assigns: %{id: id, send_updates_to: pid}}) do
    send(pid, {:updated_uploads, id, images})
  end

  defp notify_changed(_, _) do
    nil
  end

  def render(assigns) do
    ~F"""
    <style>
      .preview-items {
      @apply grid grid-cols-1 md:grid-cols-6 gap-1 justify-items-stretch w-full;
      }

      .preview-item {
      @apply bg-base-100 mx-auto my-auto w-full h-full flex flex-col justify-center items-center;
      }

      .preview-item:first-child:nth-last-child(1) {
      @apply md:col-span-1 w-full;
      }

      .preview-item:nth-child(-n + 2) {
      @apply md:col-span-3;
      }

      .preview-item:nth-child(2) ~ .preview-item {
      @apply md:col-span-2;
      }

      .preview-item :deep(.non-media-file) {
      @apply flex flex-col items-center justify-center h-full;
      }

      .preview-image {
      @apply mx-auto my-auto;
      }

      .upload-name {
      @apply text-pretty break-words m-2;
      }
    </style>
    <bc-work-uploads id={@id} class={@class}>
      <Lightbox id={@id <> "-preview-lightbox"}>
        <div class="preview-items">
          {#for {type, wupload} <- @work_uploads}
            <div class="preview-item">
              {#if type == :existing && !is_nil(wupload.preview_id)}
                <Lightbox.Item download={if @can_download? do
                  ~p"/studios/#{@studio.handle}/works/#{@work.public_id}/upload/#{wupload.upload_id}"
                end}>
                  <img
                    class="preview-image"
                    src={~p"/studios/#{@studio.handle}/works/#{@work.public_id}/upload/#{wupload.upload_id}/preview"}
                  />
                </Lightbox.Item>
              {#elseif type == :existing}
                <Icon name="file-up" class="non-media-file" size={32} label={wupload.upload.name}>
                  <span class="upload-name">{wupload.upload.name}</span>
                </Icon>
              {#elseif type == :live && Uploads.media?(wupload.client_type)}
                <Lightbox.Item>
                  <.live_img_preview entry={wupload} class="preview-image" />
                </Lightbox.Item>
              {#else}
                <Icon name="file-up" class="non-media-file" size={32} label={wupload.client_name}>
                  <span class="upload-name">{wupload.client_name}</span>
                </Icon>
              {/if}
            </div>
          {/for}
        </div>
      </Lightbox>
    </bc-work-uploads>
    """
  end
end
