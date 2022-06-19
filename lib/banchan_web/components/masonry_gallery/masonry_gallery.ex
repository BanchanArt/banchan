defmodule BanchanWeb.Components.MasonryGallery do
  @moduledoc """
  Masonry gallery component. Arranges a bunch of Uploads into a nice gallery grid.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.MasonryGallery

  prop images, :list, required: true
  prop entries, :list, required: true
  prop send_updates_to, :any

  def update(assigns, socket) do
    if assigns[:entries] != socket.assigns[:entries] do
      images =
        assigns.images
        |> Enum.filter(fn {type, data} ->
          if type == :live do
            # Keep only if it exists in the new uploads list.
            Enum.find(assigns[:entries], &(&1.ref == data.ref))
          else
            true
          end
        end)

      new_images =
        assigns[:entries]
        |> Enum.filter(fn entry ->
          !Enum.find(assigns.images, fn {type, data} ->
            type == :live && data.ref == entry.ref
          end)
        end)
        |> Enum.map(&{:live, &1})

      notify_changed(images ++ new_images, socket)
    end

    socket = socket |> assign(assigns)
    {:ok, socket}
  end

  defp notify_changed(_, %{assigns: %{send_updates_to: nil}}) do
    nil
  end

  defp notify_changed(images, %{assigns: %{id: id, send_updates_to: pid}}) do
    send(pid, {:updated_gallery_images, id, images})
  end

  defp notify_changed(_, _) do
    nil
  end

  def render(assigns) do
    ~F"""
    <div class="grid auto-rows-gallery gap-0.5 grid-cols-1 sm:grid-cols-2 md:grid-cols-3">
      {#for image <- @images}
        {#case image}
          {#match {:existing, upload}}
            <MasonryGallery.Upload upload={upload} />
          {#match {:live, entry}}
            <MasonryGallery.LiveImgPreview entry={entry} />
        {/case}
      {/for}
    </div>
    """
  end
end