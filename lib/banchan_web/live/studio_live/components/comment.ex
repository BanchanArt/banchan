defmodule BanchanWeb.StudioLive.Components.Comment do
  @moduledoc """
  Component for commission page comments
  """
  use BanchanWeb, :component

  prop studio, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp fmt_md(md) do
    HtmlSanitizeEx.markdown_html(Earmark.as_html!(md || ""))
  end

  def render(assigns) do
    ~F"""
    <div class="shadow-lg bg-base-200 rounded-box border-2">
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
            {#for attachment <- @event.attachments}
              <li class="w-32 h-32">
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
                  {#if attachment.thumbnail}
                    <img
                      class="rounded-box"
                      src={Routes.commission_attachment_path(
                        Endpoint,
                        :thumbnail,
                        @studio.handle,
                        @commission.public_id,
                        attachment.upload.key
                      )}
                    />
                  {#else}
                    {attachment.upload.name}
                  {/if}
                </a>
              </li>
            {/for}
          </ul>
        </div>
      {/if}
    </div>
    """
  end
end
