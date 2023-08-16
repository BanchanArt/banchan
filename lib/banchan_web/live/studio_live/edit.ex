defmodule BanchanWeb.StudioLive.Edit do
  @moduledoc """
  Edit Studio profile details (separate from Studio settings).
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Form

  alias Banchan.Studios
  alias Banchan.Studios.Studio
  alias Banchan.Uploads

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.{Collapse, Layout}

  alias BanchanWeb.Components.Form.{
    HiddenInput,
    Submit,
    TagsInput,
    TextArea,
    TextInput,
    UploadInput
  }

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    {:ok,
     assign(socket,
       tags: socket.assigns.studio.tags,
       changeset: Studio.profile_changeset(socket.assigns.studio, %{}),
       remove_card: false,
       remove_header: false
     )
     |> allow_upload(:card_image,
       accept: Uploads.supported_image_format_extensions(),
       max_entries: 1,
       max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
     )
     |> allow_upload(:header_image,
       accept: Uploads.supported_image_format_extensions(),
       max_entries: 1,
       max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
     )}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("submit", val, socket) do
    card_image =
      consume_uploaded_entries(socket, :card_image, fn %{path: path}, entry ->
        {:ok,
         Studios.make_card_image!(
           socket.assigns.current_user,
           path,
           socket.assigns.current_user_member? || :admin in socket.assigns.current_user.roles ||
             :mod in socket.assigns.current_user.roles,
           entry.client_type,
           entry.client_name
         )}
      end)
      |> Enum.at(0)

    header_image =
      consume_uploaded_entries(socket, :header_image, fn %{path: path}, entry ->
        {:ok,
         Studios.make_header_image!(
           socket.assigns.current_user,
           path,
           socket.assigns.current_user_member? || :admin in socket.assigns.current_user.roles ||
             :mod in socket.assigns.current_user.roles,
           entry.client_type,
           entry.client_name
         )}
      end)
      |> Enum.at(0)

    case Studios.update_studio_profile(
           socket.assigns.current_user,
           socket.assigns.studio,
           Enum.into(val["studio"], %{
             "card_img_id" => (card_image && card_image.id) || val["studio"]["card_image_id"],
             "header_img_id" =>
               (header_image && header_image.id) || val["studio"]["header_image_id"]
           })
         ) do
      {:ok, studio} ->
        socket =
          socket
          |> assign(changeset: Studio.profile_changeset(studio, %{}), studio: studio)
          |> put_flash(:info, "Profile updated")
          |> push_navigate(to: Routes.studio_shop_path(Endpoint, :show, studio.handle))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to edit this studio")
         |> push_navigate(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.studio
      |> Studio.profile_changeset(val["studio"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_card_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:card_image, ref)}
  end

  @impl true
  def handle_event("cancel_header_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:header_image, ref)}
  end

  def handle_event("remove_card", _, socket) do
    {:noreply, assign(socket, remove_card: true)}
  end

  def handle_event("remove_header", _, socket) do
    {:noreply, assign(socket, remove_header: true)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} studio={@studio} padding={0} context={:studio}>
      <div class="w-full bg-base-200">
        <div class="w-full max-w-5xl p-10 mx-auto">
          <h2 class="py-6 text-xl">Edit Studio Profile</h2>
          <Form class="flex flex-col gap-2" for={@changeset} change="change" submit="submit">
            <TextInput name={:name} info="Display name for studio" icon="user" opts={required: true} />
            <TextInput name={:handle} icon="at-sign" opts={required: true} />
            <div class="relative">
              {#if Enum.empty?(@uploads.card_image.entries) && (@remove_card || !(@studio && @studio.card_img_id))}
                <HiddenInput name={:card_image_id} value={nil} />
                <div class="w-full aspect-video bg-base-300" />
              {#elseif !Enum.empty?(@uploads.card_image.entries)}
                <button
                  type="button"
                  phx-value-ref={(@uploads.card_image.entries |> Enum.at(0)).ref}
                  class="absolute btn btn-xs btn-circle right-2 top-2"
                  :on-click="cancel_card_upload"
                >✕</button>
                <.live_img_preview
                  entry={Enum.at(@uploads.card_image.entries, 0)}
                  class="object-cover w-full aspect-video rounded-xl"
                />
              {#else}
                <button
                  type="button"
                  class="absolute btn btn-xs btn-circle right-2 top-2"
                  :on-click="remove_card"
                >✕</button>
                <HiddenInput name={:card_image_id} value={@studio.card_img_id} />
                <img
                  class="object-cover w-full aspect-video rounded-xl"
                  src={Routes.public_image_path(Endpoint, :image, :studio_card_img, @studio.card_img_id)}
                />
              {/if}
            </div>
            <UploadInput
              label="Card Image"
              hide_list
              crop
              aspect_ratio={16 / 9}
              upload={@uploads.card_image}
              cancel="cancel_card_upload"
            />
            <div class="relative">
              {#if Enum.empty?(@uploads.header_image.entries) &&
                  (@remove_header || !(@studio && @studio.header_img_id))}
                <HiddenInput name={:header_image_id} value={nil} />
                <div class="w-full aspect-header-image bg-base-300" />
              {#elseif !Enum.empty?(@uploads.header_image.entries)}
                <button
                  type="button"
                  phx-value-ref={(@uploads.header_image.entries |> Enum.at(0)).ref}
                  class="absolute btn btn-xs btn-circle right-2 top-2"
                  :on-click="cancel_header_upload"
                >✕</button>
                <.live_img_preview
                  entry={Enum.at(@uploads.header_image.entries, 0)}
                  class="object-cover w-full aspect-header-image rounded-xl"
                />
              {#else}
                <button
                  type="button"
                  class="absolute btn btn-xs btn-circle right-2 top-2"
                  :on-click="remove_header"
                >✕</button>
                <HiddenInput name={:header_image_id} value={@studio.header_img_id} />
                <img
                  class="object-cover w-full aspect-header-image rounded-xl"
                  src={Routes.public_image_path(Endpoint, :image, :studio_header_img, @studio.header_img_id)}
                />
              {/if}
            </div>
            <UploadInput
              label="Header Image"
              crop
              aspect_ratio={3.5 / 1}
              hide_list
              upload={@uploads.header_image}
              cancel="cancel_header_upload"
            />
            <TextArea
              info="Displayed in the 'About' page. The first few dozen characters will also be displayed as the description in studio cards."
              name={:about}
            />
            <TagsInput
              id="studio_tags"
              info="Type to search for existing tags. Press Enter or Tab to add the tag. You can make it whatever you want as long as it's 100 characters or shorter."
              name={:tags}
            />
            <Collapse id="socials" class="my-4">
              <:header>
                Links and Social Media
              </:header>
              <TextInput name={:website_url} />
              <TextInput name={:twitter_handle} />
              <TextInput name={:instagram_handle} />
              <TextInput name={:facebook_url} />
              <TextInput name={:furaffinity_handle} />
              <TextInput name={:discord_handle} />
              <TextInput name={:artstation_handle} />
              <TextInput name={:deviantart_handle} />
              <TextInput name={:tumblr_handle} />
              <TextInput name={:mastodon_handle} />
              <TextInput name={:twitch_channel} />
              <TextInput name={:picarto_channel} />
              <TextInput name={:pixiv_url} />
              <TextInput name={:pixiv_handle} />
              <TextInput name={:tiktok_handle} />
              <TextInput name={:artfight_handle} />
            </Collapse>
            <Submit label="Save" />
          </Form>
        </div>
      </div>
    </Layout>
    """
  end
end
