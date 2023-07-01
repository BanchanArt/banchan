defmodule BanchanWeb.CommissionLive.Components.Attachments do
  @moduledoc """
  Container for attachments, both for live uploads and for display.
  """
  use BanchanWeb, :live_component

  alias Banchan.Uploads

  alias Surface.Components.LiveFileInput

  alias BanchanWeb.CommissionLive.Components.Attachments
  alias BanchanWeb.Components.Lightbox

  prop upload, :struct
  prop cancel_upload, :event

  def render(assigns) do
    ~F"""
    <div id={@id} class="flex flex-col gap-4">
      <Lightbox id={@id <> "-lightbox"} class="flex flex-row flex-wrap gap-4 p-2">
        {!-- # TODO
          <Attachments.UploadImgPreview deleted="item_deleted" upload={upload} />
          --}
        {#if @upload}
          {#for entry <- @upload.entries |> Enum.filter(&Uploads.image?(&1.client_type))}
            <Attachments.LiveImgPreview cancel={@cancel_upload} upload={@upload} entry={entry} />
          {/for}
          <Attachments.ImageAttachment>
            <label class="w-full h-full rounded-box bg-base-content flex justify-center items-center cursor-pointer">
              <div class="text-base-100 text-xl">
                <i class="fas fa-plus" />
              </div>
              <LiveFileInput class="absolute hidden overflow-hidden" upload={@upload} />
            </label>
          </Attachments.ImageAttachment>
        {/if}
      </Lightbox>
      {#if @upload}
        {#for entry <- @upload.entries}
          <Attachments.FileAttachment cancel={@cancel_upload} upload={@upload} entry={entry} />
        {/for}
        {#for err <- upload_errors(@upload)}
          <p class="text-error">{Uploads.error_to_string(err)}</p>
        {/for}
      {/if}
    </div>
    """
  end
end
