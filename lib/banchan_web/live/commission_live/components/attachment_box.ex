defmodule BanchanWeb.CommissionLive.Components.AttachmentBox do
  @moduledoc """
  Displays a flexbox of attachments for a commission.
  """
  use BanchanWeb, :component

  alias Banchan.Uploads

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
      <ul class="flex flex-row flex-wrap gap-4 p-2">
        {#for attachment <- Enum.filter(@attachments, & &1.thumbnail_id)}
          <li class="h-32 w-32">
            {#if @pending_payment && !@current_user_member?}
              <div
                class="w-full h-full rounded-box bg-base-content flex justify-center items-center"
                title={attachment.upload.name}
              >
                <div class="text-base-100 text-3xl">
                  <i class="fas fa-lock" />
                </div>
              </div>
            {#else}
              <button
                class="relative"
                :on-click={@open_preview}
                phx-value-key={attachment.upload.key}
                phx-value-bucket={attachment.upload.bucket}
              >
                {#if Uploads.video?(attachment.upload)}
                  <i class="fas fa-play text-4xl absolute top-10 left-10" />
                {/if}
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
                    attachment.upload.key
                  )}
                />
              </button>
            {/if}
          </li>
        {/for}
      </ul>
      <div class="flex flex-col p-2">
        {#for attachment <- Enum.filter(@attachments, &(!&1.thumbnail_id))}
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
                  attachment.upload.key
                )}
              >
                <div title={attachment.upload.name} class="border-2 p-4 m-1">
                  <i class="float-right fas fa-file-download" /> <p class="truncate">{attachment.upload.name} ({attachment.upload.type})</p>
                </div>
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
