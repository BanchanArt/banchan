defmodule BanchanWeb.OfferingLive.Show do
  @moduledoc """
  Shows details about an offering.
  """
  use BanchanWeb, :surface_view

  import BanchanWeb.StudioLive.Helpers

  alias Banchan.Offerings

  alias Surface.Components.LiveRedirect

  alias BanchanWeb.Components.{Button, Layout, Markdown, MasonryGallery}

  @impl true
  def handle_params(%{"offering_type" => offering_type} = params, uri, socket) do
    socket = assign_studio_defaults(params, socket, false, true)

    offering =
      Offerings.get_offering_by_type!(
        socket.assigns.studio,
        offering_type,
        socket.assigns.current_user_member?
      )

    gallery_images =
      offering.gallery_uploads
      |> Enum.map(&{:existing, &1})

    if is_nil(offering.archived_at) || socket.assigns.current_user_member? do
      {:noreply,
       socket
       |> assign(
         uri: uri,
         offering: offering,
         gallery_images: gallery_images
       )}
    else
      {:noreply,
       socket
       |> put_flash(:error, "This offering is unavailable.")
       |> push_redirect(to: Routes.offering_index_path(Endpoint, :index))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <div class="px-4">
        <span class="text-xl font-bold">{@offering.name}</span>
        <Markdown class="pb-4" content={@offering.description} />
        <ul class="flex flex-row flex-wrap gap-1">
          {#for tag <- @offering.tags}
            <li class="badge badge-sm badge-primary p-2 cursor-default overflow-hidden">{tag}</li>
          {/for}
        </ul>
        <div class="pt-2 flex flex-row justify-end card-actions">
          {#if @current_user_member?}
            <LiveRedirect
              to={Routes.studio_offerings_edit_path(Endpoint, :edit, @offering.studio.handle, @offering.type)}
              class="btn text-center btn-primary"
            >Edit</LiveRedirect>
          {/if}
          {#if @offering.open}
            <LiveRedirect
              to={Routes.offering_request_path(Endpoint, :new, @offering.studio.handle, @offering.type)}
              class="btn text-center btn-info"
            >Request</LiveRedirect>
          {#elseif !@offering.user_subscribed?}
            <Button class="btn-info" click="notify_me">Notify Me</Button>
          {/if}
          {#if @offering.user_subscribed?}
            <Button class="btn-info" click="unnotify_me">Unsubscribe</Button>
          {/if}
        </div>
      </div>
      <div class="pt-4">
        {#if Enum.empty?(@gallery_images)}
          <img
            class="w-full h-full"
            src={if @offering.card_img_id do
              Routes.public_image_path(Endpoint, :image, @offering.card_img_id)
            else
              Routes.static_path(Endpoint, "/images/640x360.png")
            end}
          />
        {#else}
          <MasonryGallery id="masonry-gallery" images={@gallery_images} />
        {/if}
      </div>
    </Layout>
    """
  end
end
