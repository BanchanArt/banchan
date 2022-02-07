defmodule BanchanWeb.StudioLive.Components.Comment do
  @moduledoc """
  Component for commission page comments
  """
  use BanchanWeb, :component

  alias BanchanWeb.Components.Card

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
    <Card>
      <div class="text-sm">
        <img
          class="w-6 inline-block mask mask-circle"
          src={Routes.profile_image_path(Endpoint, :thumb, @event.actor.handle)}
        />
        {@event.actor.handle} commented {fmt_time(@event.inserted_at)}.
      </div>

      <div class="content">
        {raw(fmt_md(@event.text))}
      </div>

      <:footer>
        <hr>
        <h2 class="text-xl">Attachments</h2>
        <ul class="flex space-x-4">
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
      </:footer>
    </Card>
    """
  end
end
