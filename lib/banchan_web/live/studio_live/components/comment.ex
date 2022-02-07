defmodule BanchanWeb.StudioLive.Components.Comment do
  @moduledoc """
  Component for commission page comments
  """
  use BanchanWeb, :live_component

  prop studio, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true

  data previewing, :struct

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp fmt_md(md) do
    HtmlSanitizeEx.markdown_html(Earmark.as_html!(md || ""))
  end

  @impl true
  def update(params, socket) do
    {:ok, socket |> assign(params) |> assign(previewing: nil)}
  end

  @impl true
  def handle_event("open_preview", %{"key" => key, "name" => name}, socket) do
    {:noreply, socket |> assign(previewing: %{key: key, name: name})}
  end

  @impl true
  def handle_event("close_preview", _, socket) do
    {:noreply, socket |> assign(previewing: nil)}
  end

  @impl true
  def handle_event("nothing", _, socket) do
    # This is used to prevent clicking on images from closing the preview.
    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply, socket |> assign(previewing: nil)}
  end

  def render(assigns) do
    ~F"""
    <div class="shadow-lg bg-base-200 rounded-box border-2">
      <div class={"modal", "modal-open": @previewing} :on-click="close_preview">
        {#if @previewing}
          <div :on-window-keydown="keydown">
            <img
              :on-click="nothing"
              alt={@previewing.name}
              src={Routes.commission_attachment_path(
                Endpoint,
                :show,
                @studio.handle,
                @commission.public_id,
                @previewing.key
              )}
            />
          </div>
          <button
            :on-click="close_preview"
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
              @previewing.key
            )}
          >
            <i class="float-right fas fa-file-download" />
          </a>
        {/if}
      </div>
      <div class="text-sm p-2">
        <a href={"/denizens/#{@event.actor.handle}"}>
          <img
            class="w-6 inline-block mask mask-circle"
            src={Routes.profile_image_path(Endpoint, :thumb, @event.actor.handle)}
          />
          <strong>{@event.actor.handle}</strong></a>
        commented {fmt_time(@event.inserted_at)}.
      </div>

      <hr>

      <div class="content p-4 h-24 min-h-full user-markdown">
        {raw(fmt_md(@event.text))}
      </div>

      {#if Enum.any?(@event.attachments)}
        <hr>
        <div class="p-4">
          <ul class="flex space-x-4 p-2">
            {#for attachment <- Enum.filter(@event.attachments, & &1.thumbnail)}
              <li class="h-32 w-32">
                <button
                  :on-click="open_preview"
                  phx-value-key={attachment.upload.key}
                  phx-value-name={attachment.upload.name}
                >
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
                  <i class="float-right fas fa-file-download" /> <p class="truncate">{attachment.upload.name}</p>
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
