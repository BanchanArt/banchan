defmodule BanchanWeb.StudioLive.Components.Comment do
  @moduledoc """
  Component for commission page comments
  """
  use BanchanWeb, :live_component

  alias Banchan.Uploads

  alias BanchanWeb.StudioLive.Components.MediaPreview

  prop studio, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true
  prop uri, :string, required: true

  data previewing, :struct

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp fmt_md(md) do
    HtmlSanitizeEx.markdown_html(Earmark.as_html!(md || ""))
  end

  @impl true
  def handle_event("open_preview", %{"key" => key, "bucket" => bucket}, socket) do
    MediaPreview.open(
      "preview-#{socket.assigns.event.public_id}",
      Uploads.get_upload!(bucket, key)
    )

    {:noreply, socket}
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  def render(assigns) do
    ~F"""
    <div class="shadow-lg bg-base-200 rounded-box border-2">
      <MediaPreview id={"preview-#{@event.public_id}"} commission={@commission} studio={@studio} />
      <div class="text-sm p-2">
        <a href={"/denizens/#{@event.actor.handle}"}>
          <img
            class="w-6 inline-block mask mask-circle"
            src={Routes.profile_image_path(Endpoint, :thumb, @event.actor.handle)}
          />
          <strong class="hover:underline">{@event.actor.handle}</strong></a>
        commented <a class="hover:underline" href={replace_fragment(@uri, @event)}>{fmt_time(@event.inserted_at)}</a>.
      </div>

      <hr>

      <div class="content p-4 h-24 min-h-full user-markdown">
        {raw(fmt_md(@event.text))}
      </div>

      {#if Enum.any?(@event.attachments)}
        <hr>
        <div class="p-4">
          <ul class="flex flex-wrap gap-4 p-2">
            {#for attachment <- Enum.filter(@event.attachments, & &1.thumbnail)}
              <li class="h-32 w-32">
                <button
                  class="relative"
                  :on-click="open_preview"
                  phx-value-key={attachment.upload.key}
                  phx-value-bucket={attachment.upload.bucket}
                >
                  {#if Uploads.video?(attachment.upload)}
                    <i class="fas fa-play text-4xl absolute top-10 left-10" />
                  {/if}
                  <img
                    alt={attachment.upload.name}
                    title={attachment.upload.name}
                    class="rounded-box"
                    src={Routes.commission_attachment_path(
                      Endpoint,
                      :thumbnail,
                      @studio.handle,
                      @commission.public_id,
                      attachment.upload.key
                    )}
                  />
                </button>
              </li>
            {/for}
          </ul>
          <div class="flex flex-col p-2">
            {#for attachment <- Enum.filter(@event.attachments, &(!&1.thumbnail))}
              <a
                target="_blank"
                href={Routes.commission_attachment_path(
                  Endpoint,
                  :show,
                  @studio.handle,
                  @commission.public_id,
                  attachment.upload.key
                )}
              >
                <div title={attachment.upload.name} class="border-2 p-4 m-1">
                  <i class="float-right fas fa-file-download" /> <p class="truncate">{attachment.upload.name} ({attachment.upload.type})</p>
                </div>
              </a>
            {/for}
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
