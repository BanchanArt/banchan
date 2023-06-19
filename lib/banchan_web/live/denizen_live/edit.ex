defmodule BanchanWeb.DenizenLive.Edit do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts

  alias BanchanWeb.Components.Form.{
    CropUploadInput,
    HiddenInput,
    Submit,
    TagsInput,
    TextArea,
    TextInput
  }

  alias BanchanWeb.Components.{Collapse, Layout}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    user = Accounts.get_user_by_handle!(handle)

    if user.id != socket.assigns.current_user.id &&
         :admin not in socket.assigns.current_user.roles &&
         :mod not in socket.assigns.current_user.roles do
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page.")
       |> push_navigate(to: Routes.denizen_show_path(Endpoint, :show, handle))}
    else
      {:ok,
       socket
       |> assign(
         user: user,
         changeset: User.profile_changeset(user),
         tags: user.tags,
         remove_header: false,
         remove_pfp: false
       )
       |> allow_upload(:pfp,
         accept: ~w(image/jpeg image/png),
         max_entries: 1,
         max_file_size: 5_000_000
       )
       |> allow_upload(:header,
         accept: ~w(image/jpeg image/png),
         max_entries: 1,
         max_file_size: 5_000_000
       )}
    end
  end

  @impl true
  def handle_event("change", %{"user" => user}, socket) do
    changeset =
      socket.assigns.user
      |> User.profile_changeset(user)
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)

    {:noreply, socket}
  end

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("submit", %{"user" => user}, socket) do
    {pfp, thumb} =
      case consume_uploaded_entries(socket, :pfp, fn %{path: path}, entry ->
             {:ok,
              Accounts.make_pfp_images!(
                socket.assigns.current_user,
                socket.assigns.user,
                path,
                entry.client_type,
                entry.client_name
              )}
           end)
           |> Enum.at(0) do
        {pfp, thumb} ->
          {pfp, thumb}

        nil ->
          {nil, nil}
      end

    header_image =
      consume_uploaded_entries(socket, :header, fn %{path: path}, entry ->
        {:ok,
         Accounts.make_header_image!(
           socket.assigns.current_user,
           socket.assigns.user,
           path,
           entry.client_type,
           entry.client_name
         )}
      end)
      |> Enum.at(0)

    case Accounts.update_user_profile(
           socket.assigns.current_user,
           socket.assigns.user,
           Enum.into(user, %{
             "pfp_img_id" => (pfp && pfp.id) || user["pfp_image_id"],
             "pfp_thumb_id" => (thumb && thumb.id) || user["pfp_thumbnail_id"],
             "header_img_id" => (header_image && header_image.id) || user["header_image_id"]
           })
         ) do
      {:ok, user} ->
        socket = assign(socket, changeset: User.profile_changeset(user), user: user)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_navigate(socket, to: Routes.denizen_show_path(Endpoint, :show, user.handle))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("cancel_pfp_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:pfp, ref)}
  end

  @impl true
  def handle_event("cancel_header_upload", %{"ref" => ref}, socket) do
    {:noreply, socket |> cancel_upload(:header, ref)}
  end

  def handle_event("remove_pfp", _, socket) do
    {:noreply, assign(socket, remove_pfp: true)}
  end

  def handle_event("remove_header", _, socket) do
    {:noreply, assign(socket, remove_header: true)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} padding={0}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Form class="profile-info" for={@changeset} change="change" submit="submit">
            <div :if={@current_user.id != @user.id} class="alert alert-warning">
              You are editing @{@user.handle}'s profile as @{@current_user.handle}.
            </div>
            <div class="relative">
              {#if Enum.empty?(@uploads.header.entries) && (@remove_header || !@user.header_img_id)}
                <HiddenInput name={:header_image_id} value={nil} />
                <div class="bg-base-300 object-cover aspect-header-image rounded-b-xl w-full" />
              {#elseif !Enum.empty?(@uploads.header.entries)}
                <button
                  type="button"
                  phx-value-ref={(@uploads.header.entries |> Enum.at(0)).ref}
                  class="btn btn-xs btn-circle absolute right-2 top-2 z-20"
                  :on-click="cancel_header_upload"
                >✕</button>
                <.live_img_preview
                  entry={Enum.at(@uploads.header.entries, 0)}
                  class="object-cover aspect-header-image rounded-b-xl w-full"
                />
              {#elseif @user.header_img_id}
                <button
                  type="button"
                  class="btn btn-xs btn-circle absolute right-2 top-2 z-20"
                  :on-click="remove_header"
                >✕</button>
                <HiddenInput name={:header_image_id} value={@user.header_img_id} />
                <img
                  class="object-cover aspect-header-image rounded-b-xl w-full"
                  src={Routes.public_image_path(Endpoint, :image, :user_header_img, @user.header_img_id)}
                />
              {/if}
              <div class="absolute top-0 left-0 w-full h-full">
                <div class="mx-auto w-full h-full flex justify-center items-center">
                  <div class="relative">
                    <button type="button" class="absolute top-0 left-0 btn btn-sm btn-circle opacity-70"><i class="fas fa-camera" /></button>
                    <CropUploadInput
                      id="header-cropper"
                      aspect_ratio={3.5 / 1}
                      title="Crop Header Image"
                      upload={@uploads.header}
                      class="h-8 w-8 opacity-0 hover:cursor-pointer z-40"
                    />
                  </div>
                </div>
              </div>
            </div>
            <div class="relative w-24 h-20">
              <div class="absolute -top-4 left-6">
                <div class="relative flex justify-center items-center w-24">
                  <div class="avatar">
                    <div class="rounded-full w-24">
                      {#if Enum.empty?(@uploads.pfp.entries) && (@remove_pfp || !(@user.pfp_img_id && @user.pfp_thumb_id))}
                        <HiddenInput name={:pfp_image_id} value={nil} />
                        <HiddenInput name={:pfp_thumbnail_id} value={nil} />
                        <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
                      {#elseif !Enum.empty?(@uploads.pfp.entries)}
                        <button
                          type="button"
                          phx-value-ref={(@uploads.pfp.entries |> Enum.at(0)).ref}
                          class="btn btn-xs btn-circle absolute right-2 top-2"
                          :on-click="cancel_pfp_upload"
                        >✕</button>
                        <.live_img_preview entry={Enum.at(@uploads.pfp.entries, 0)} />
                      {#else}
                        <button type="button" class="btn btn-xs btn-circle absolute right-2 top-2" :on-click="remove_pfp">✕</button>
                        <HiddenInput name={:pfp_image_id} value={@user.pfp_img_id} />
                        <HiddenInput name={:pfp_thumb_id} value={@user.pfp_thumb_id} />
                        <img src={Routes.public_image_path(Endpoint, :image, :user_pfp_img, @user.pfp_img_id)}>
                      {/if}
                    </div>
                  </div>
                  <div class="absolute top-8 left-8 w-8">
                    <div class="relative">
                      <button type="button" class="absolute top-0 left-0 btn btn-sm btn-circle opacity-70"><i class="fas fa-camera" /></button>
                      <CropUploadInput
                        id="pfp-cropper"
                        aspect_ratio={1}
                        title="Crop Profile Picture"
                        upload={@uploads.pfp}
                        class="h-8 w-8 opacity-0 hover:cursor-pointer z-40"
                      />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <TextInput
              name={:handle}
              icon="at"
              info="For security reasons, you can only change this on your Account Settings page."
              opts={disabled: true}
            />
            <TextInput name={:name} icon="user" info="Your display name." opts={required: true} />
            <TextArea name={:bio} info="Tell us a little bit about yourself!" />
            <TagsInput
              id="user_tags"
              label="Interests"
              info="Type to search for existing tags. Press Enter or Tab to add the tag. You can make it whatever you want as long as it's 100 characters or shorter."
              name={:tags}
            />
            <Collapse id="socials" class="my-4 border-b-2">
              <:header>
                Links
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
