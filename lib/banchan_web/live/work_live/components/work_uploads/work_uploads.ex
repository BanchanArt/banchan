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

  def handle_event("reposition", params, socket) do
    old = params["old"]
    new = params["new"]

    new_uploads =
      if old > new do
        List.insert_at(
          socket.assigns.work_uploads,
          new,
          Enum.at(socket.assigns.work_uploads, old)
        )
        |> List.delete_at(old + 1)
      else
        List.insert_at(
          socket.assigns.work_uploads,
          new,
          Enum.at(socket.assigns.work_uploads, old)
        )
        |> List.delete_at(old)
      end

    notify_changed(new_uploads, socket)

    {:noreply, socket}
  end

  def handle_event("remove_upload", params, socket) do
    {idx, ""} = params["idx"] |> Integer.parse()
    to_remove = Enum.at(socket.assigns.work_uploads, idx)
    new_uploads = List.delete_at(socket.assigns.work_uploads, idx)
    notify_changed(new_uploads, socket)

    case to_remove do
      {:live, entry} ->
        notify_canceled(entry.ref, socket)

      _ ->
        nil
    end

    {:noreply, socket}
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

  defp notify_canceled(_, %{assigns: %{send_updates_to: nil}}) do
    nil
  end

  defp notify_canceled(ref, %{assigns: %{id: id, send_updates_to: pid}}) do
    send(pid, {:canceled_upload, id, ref})
  end

  defp get_upload_entry(entries, wupload) do
    Enum.find(entries, fn entry ->
      entry.ref == wupload.ref
    end)
  end

  def render(assigns) do
    ~F"""
    <bc-work-uploads id={@id} class={@class} :hook="SortableHook">
      <Lightbox id={@id <> "-preview-lightbox"}>
        <div id={@id <> "-items"} class="preview-items" data-list_id={@id <> "-list"}>
          {#for {{type, wupload}, idx} <- @work_uploads |> Enum.with_index()}
            <div
              class="preview-item"
              data-id={if type == :existing do
                wupload.upload.id
              else
                wupload.ref
              end}
            >
              {#if type == :live}
                <div
                  class="upload-progress"
                  style={"--value:#{get_upload_entry(@live_entries, wupload).progress}"}
                >{get_upload_entry(@live_entries, wupload).progress}%</div>
              {/if}
              {#if @editing}
                <button type="button" class="remove-upload" phx-value-idx={idx} :on-click="remove_upload">✕</button>
              {/if}
              {#if type == :existing && !is_nil(wupload.preview_id)}
                {#if @editing}
                  <img
                    class="preview-image"
                    src={~p"/studios/#{@studio.handle}/works/#{@work.public_id}/upload/#{wupload.upload_id}/preview"}
                  />
                {#else}
                  <Lightbox.Item download={if @can_download? do
                    ~p"/studios/#{@studio.handle}/works/#{@work.public_id}/upload/#{wupload.upload_id}"
                  end}>
                    <img
                      class="preview-image"
                      src={~p"/studios/#{@studio.handle}/works/#{@work.public_id}/upload/#{wupload.upload_id}/preview"}
                    />
                  </Lightbox.Item>
                {/if}
              {#elseif type == :existing}
                <Icon name="file-up" class="non-media-file" size={32} label={wupload.upload.name}>
                  <span class="upload-name">{wupload.upload.name}</span>
                </Icon>
              {#elseif type == :live && Uploads.media?(wupload.client_type)}
                {#if @editing}
                  <.live_img_preview entry={wupload} class="preview-image" />
                {#else}
                  <Lightbox.Item>
                    <.live_img_preview entry={wupload} class="preview-image" />
                  </Lightbox.Item>
                {/if}
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
