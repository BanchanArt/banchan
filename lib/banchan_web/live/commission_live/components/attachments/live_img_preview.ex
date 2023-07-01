defmodule BanchanWeb.CommissionLive.Components.Attachments.LiveImgPreview do
  @moduledoc """
  Component for displaying and managing attachments that haven't been uploaded
  yet.
  """
  use BanchanWeb, :component

  alias BanchanWeb.CommissionLive.Components.Attachments.ImageAttachment
  alias BanchanWeb.Components.Lightbox

  prop upload, :struct, required: true
  prop entry, :struct, required: true
  prop cancel, :event, required: true

  def render(assigns) do
    ~F"""
    <ImageAttachment>
      {#if @entry.progress > 0}
        <div class="radial-progress absolute" style={"--value:#{@entry.progress};"} />
      {/if}
      <button
        type="button"
        phx-value-ref={@entry.ref}
        class="btn btn-xs btn-circle absolute -right-2 -top-2 cursor-pointer"
        :on-click={@cancel}
      >✕</button>
      <Lightbox.Item class="w-full h-full">
        <.live_img_preview entry={@entry} class="w-full h-full object-cover rounded-box" />
      </Lightbox.Item>
    </ImageAttachment>
    """
  end
end
