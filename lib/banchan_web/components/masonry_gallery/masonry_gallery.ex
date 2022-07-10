defmodule BanchanWeb.Components.MasonryGallery do
  @moduledoc """
  Masonry gallery component. Arranges a bunch of Uploads into a nice gallery grid.
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.Components.MasonryGallery

  prop editable, :boolean, default: false
  prop images, :list, required: true
  prop entries, :list
  prop send_updates_to, :any
  prop class, :css_class

  def update(assigns, socket) do
    old_assigns = socket.assigns
    socket = socket |> assign(assigns)

    socket =
      if assigns[:entries] != old_assigns[:entries] do
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

        new_images = images ++ new_images

        notify_changed(new_images, socket)
        socket |> assign(images: new_images)
      else
        socket
      end

    {:ok, socket}
  end

  def handle_event("items_reordered", %{"items" => items}, socket) do
    new_images =
      items
      |> Enum.map(fn %{"type" => type, "id" => id} ->
        if type == "live" do
          Enum.find(socket.assigns.images, fn {t, data} ->
            t == :live && data.ref == id
          end)
        else
          Enum.find(socket.assigns.images, fn {t, data} ->
            t == :existing && data.id == id
          end)
        end
      end)

    notify_changed(new_images, socket)

    {:noreply, socket |> assign(images: new_images)}
  end

  def handle_event("item_deleted", %{"id" => id}, socket) do
    new_images =
      socket.assigns.images
      |> Enum.filter(fn {t, data} ->
        if t == :live do
          data.ref != id
        else
          data.id != id
        end
      end)

    notify_changed(new_images, socket)
    {:noreply, socket |> assign(images: new_images)}
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
    <div :hook="MasonryGallery" class={"gap-0 sm:gap-2 columns-2 sm:columns-3 md:columns-4", @class}>
      {#for image <- @images}
        {#case image}
          {#match {:existing, upload}}
            <MasonryGallery.Upload deleted="item_deleted" upload={upload} editable={@editable} />
          {#match {:live, entry}}
            <MasonryGallery.LiveImgPreview deleted="item_deleted" entry={entry} editable={@editable} />
        {/case}
      {/for}
    </div>
    """
  end
end
