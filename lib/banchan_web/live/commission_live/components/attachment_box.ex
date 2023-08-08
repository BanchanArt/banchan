defmodule BanchanWeb.CommissionLive.Components.AttachmentBox do
  @moduledoc """
  Displays a flexbox of attachments for a commission.
  """
  use BanchanWeb, :component

  alias Banchan.Uploads

  alias BanchanWeb.Components.Icon
  alias BanchanWeb.Components.Lightbox

  prop base_id, :string, required: true
  prop commission, :struct, from_context: :commission
  prop attachments, :list, required: true
  prop editing, :boolean, default: false
  prop pending_payment, :boolean, default: false
  prop current_user_member?, :boolean, from_context: :current_user_member?

  prop open_preview, :event
  prop remove_attachment, :event

  defp get_attachment_index(attachments, attachment) do
    Enum.find_index(attachments, &(&1 == attachment))
  end

  def render(assigns) do
    ~F"""
    <div>
      {#if @pending_payment}
        <div class="text-sm italic">
          These files will be available after payment is processed.
        </div>
      {/if}
      <Lightbox id={@base_id <> "-attachment-box-lightbox"} class="flex flex-row flex-wrap gap-4 p-2">
        {#for attachment <- Enum.filter(@attachments, &(&1.thumbnail_id && !Uploads.video?(&1.upload)))}
          <div class="w-32 h-32">
            {#if @pending_payment}
              <div
                class="flex items-center justify-center w-full h-full rounded-box bg-base-content"
                title={attachment.upload.name}
              >
                <div class="text-3xl text-base-100">
                  <Icon name="lock" size="4" />
                </div>
              </div>
            {#elseif attachment.thumbnail.pending || attachment.preview.pending}
              <div
                class="flex items-center justify-center w-full h-full rounded-box bg-base-content animate-pulse"
                title={attachment.upload.name}
              />
            {#elseif @editing}
              <div class="relative">
                {#if @editing}
                  <button
                    type="button"
                    :on-click={@remove_attachment}
                    phx-value-attachment-idx={get_attachment_index(@attachments, attachment)}
                    class="absolute -top-2 -right-2"
                  >
                    <Icon name="x-circle" size="4" />
                  </button>
                {/if}
                <img
                  alt={attachment.upload.name}
                  title={attachment.upload.name}
                  class="rounded-box"
                  src={Routes.commission_attachment_path(
                    Endpoint,
                    :thumbnail,
                    @commission.public_id,
                    attachment.upload_id
                  )}
                />
              </div>
            {#else}
              <Lightbox.Item
                class="relative"
                media={if Uploads.video?(attachment.upload) do
                  :video
                else
                  :image
                end}
                download={Routes.commission_attachment_path(
                  Endpoint,
                  :show,
                  @commission.public_id,
                  attachment.upload_id
                )}
                src={Routes.commission_attachment_path(
                  Endpoint,
                  :preview,
                  @commission.public_id,
                  attachment.upload_id
                )}
              >
                {#if @editing}
                  <button
                    type="button"
                    :on-click={@remove_attachment}
                    phx-value-attachment-idx={get_attachment_index(@attachments, attachment)}
                    class="absolute -top-2 -right-2"
                  >
                    <Icon name="x-circle" size="4" />
                  </button>
                {/if}
                <img
                  alt={attachment.upload.name}
                  title={attachment.upload.name}
                  class="rounded-box"
                  src={Routes.commission_attachment_path(
                    Endpoint,
                    :thumbnail,
                    @commission.public_id,
                    attachment.upload_id
                  )}
                />
              </Lightbox.Item>
            {/if}
          </div>
        {/for}
      </Lightbox>
      <div class="flex flex-col p-2">
        {#for attachment <- Enum.filter(@attachments, &(!&1.thumbnail_id || Uploads.video?(&1.upload)))}
          {#if @pending_payment}
            <div title={attachment.upload.name} class="p-4 m-1 border-2">
              <Icon name="lock" size="4" class="float-right" /> <p class="truncate">{attachment.upload.name} ({attachment.upload.type})</p>
            </div>
          {#else}
            <div class="relative">
              <a
                class="relative"
                target="_blank"
                href={Routes.commission_attachment_path(
                  Endpoint,
                  :show,
                  @commission.public_id,
                  attachment.upload_id
                )}
              >
                {#if Uploads.video?(attachment.upload)}
                  <div class="flex justify-center h-[128px] w-[128px]">
                    <div
                      class="absolute z-0 h-[128px] w-[128px] rounded-box bg-base-content animate-pulse"
                      title={attachment.upload.name}
                    />
                    <img
                      alt={attachment.upload.name}
                      title={attachment.upload.name}
                      class="absolute z-10 rounded-box"
                      src={Routes.commission_attachment_path(
                        Endpoint,
                        :thumbnail,
                        @commission.public_id,
                        attachment.upload_id
                      )}
                    />
                    <div class="absolute z-20 pt-11">
                      <Icon name="play" size="4" />
                    </div>
                  </div>
                {#else}
                  <div title={attachment.upload.name} class="p-4 m-1 border-2 basis-full">
                    <Icon name="file-down" size="4" class="float-right" />
                    <p class="truncate">{attachment.upload.name} ({attachment.upload.type})</p>
                  </div>
                {/if}
              </a>
              {#if @editing}
                <button
                  type="button"
                  :on-click={@remove_attachment}
                  phx-value-attachment-idx={get_attachment_index(@attachments, attachment)}
                  class="absolute -top-2 -right-2"
                >
                  <Icon name="x-circle" size="4" />
                </button>
              {/if}
            </div>
          {/if}
        {/for}
      </div>
    </div>
    """
  end
end
