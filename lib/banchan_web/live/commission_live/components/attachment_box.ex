defmodule BanchanWeb.CommissionLive.Components.AttachmentBox do
  @moduledoc """
  Displays a flexbox of attachments for a commission.
  """
  use BanchanWeb, :component

  alias Banchan.Uploads

  alias BanchanWeb.Components.Lightbox

  prop base_id, :string, required: true
  prop commission, :struct, required: true
  prop attachments, :list, required: true
  prop editing, :boolean, default: false
  prop pending_payment, :boolean, default: false
  prop current_user_member?, :boolean, default: false

  prop open_preview, :event
  prop remove_attachment, :event

  defp get_attachment_index(attachments, attachment) do
    Enum.find_index(attachments, &(&1 == attachment))
  end

  def render(assigns) do
    ~F"""
    <div>
      {#if @pending_payment}
        <div class="italic text-sm">
          These files will be available after payment is processed.
        </div>
      {/if}
      <Lightbox id={@base_id <> "-attachment-box-lightbox"} class="flex flex-row flex-wrap gap-4 p-2">
        {#for attachment <- Enum.filter(@attachments, &(&1.thumbnail_id && !Uploads.video?(&1.upload)))}
          <div class="h-32 w-32">
            {#if @pending_payment && !@current_user_member?}
              <div
                class="w-full h-full rounded-box bg-base-content flex justify-center items-center"
                title={attachment.upload.name}
              >
                <div class="text-base-100 text-3xl">
                  <i class="fas fa-lock" />
                </div>
              </div>
            {#elseif attachment.thumbnail.pending || attachment.preview.pending}
              <div
                class="w-full h-full rounded-box bg-base-content flex justify-center items-center animate-pulse"
                title={attachment.upload.name}
              />
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
                  <a
                    href="#"
                    :on-click={@remove_attachment}
                    phx-value-attachment-idx={get_attachment_index(@attachments, attachment)}
                    class="-top-2 -right-2 absolute"
                  >
                    <i class="fas fa-times-circle text-2xl" />
                  </a>
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
          {#if @pending_payment && !@current_user_member?}
            <div title={attachment.upload.name} class="border-2 p-4 m-1">
              <i class="float-right fas fa-lock" /> <p class="truncate">{attachment.upload.name} ({attachment.upload.type})</p>
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
                      class="rounded-box absolute z-10"
                      src={Routes.commission_attachment_path(
                        Endpoint,
                        :thumbnail,
                        @commission.public_id,
                        attachment.upload_id
                      )}
                    />
                    <i class="fas fa-play text-4xl absolute pt-[44px] z-20" />
                  </div>
                {#else}
                  <div title={attachment.upload.name} class="border-2 p-4 m-1 basis-full">
                    <i class="float-right fas fa-file-download" /> <p class="truncate">{attachment.upload.name} ({attachment.upload.type})</p>
                  </div>
                {/if}
              </a>
              {#if @editing}
                <a
                  href="#"
                  :on-click={@remove_attachment}
                  phx-value-attachment-idx={get_attachment_index(@attachments, attachment)}
                  class="-top-2 -right-2 absolute"
                >
                  <i class="fas fa-times-circle text-2xl" />
                </a>
              {/if}
            </div>
          {/if}
        {/for}
      </div>
    </div>
    """
  end
end
