defmodule BanchanWeb.DenizenLive.Edit do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.{Form, LiveFileInput}

  alias Banchan.Accounts

  alias BanchanWeb.Components.Form.{Submit, TagsInput, TextArea, TextInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    user = Accounts.get_user_by_handle!(handle)

    {:ok,
     socket
     |> assign(user: user, changeset: User.profile_changeset(user), tags: user.tags)
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

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.user
      |> User.profile_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)

    Ecto.Changeset.fetch_field(changeset, :tags)

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    pfp_images =
      consume_uploaded_entries(socket, :pfp, fn %{path: path}, _entry ->
        {:ok,
         Accounts.make_pfp_images!(
           socket.assigns.user,
           path,
           socket.assigns.user.id == socket.assigns.current_user.id
         )}
      end)

    header_images =
      consume_uploaded_entries(socket, :header, fn %{path: path}, _entry ->
        {:ok,
         Accounts.make_header_image!(
           socket.assigns.user,
           path,
           socket.assigns.user.id == socket.assigns.current_user.id
         )}
      end)

    case Accounts.update_user_profile(
           socket.assigns.user,
           val["user"],
           Enum.at(pfp_images, 0),
           Enum.at(header_images, 0)
         ) do
      {:ok, user} ->
        socket = assign(socket, changeset: User.profile_changeset(user), user: user)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_redirect(socket, to: Routes.denizen_show_path(Endpoint, :show, user.handle))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} padding={0} current_user={@current_user} flashes={@flash}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Form class="profile-info" for={@changeset} change="change" submit="submit">
            <div class="relative">
              {#if Enum.empty?(@uploads.header.entries) && !@user.header_img_id}
                <div class="bg-base-300 object-cover aspect-header-image rounded-b-xl w-full" />
              {#elseif !Enum.empty?(@uploads.header.entries)}
                {Phoenix.LiveView.Helpers.live_img_preview(Enum.at(@uploads.header.entries, 0),
                  class: "object-cover aspect-header-image rounded-b-xl w-full"
                )}
              {#elseif @user.header_img_id}
                <img
                  class="object-cover aspect-header-image rounded-b-xl w-full"
                  src={Routes.public_image_path(Endpoint, :image, @user.header_img_id)}
                />
              {/if}
              <div class="absolute top-0 left-0 w-full h-full">
                <div class="mx-auto w-full h-full flex justify-center items-center">
                  <div class="relative">
                    <button type="button" class="absolute top-0 left-0 btn btn-sm btn-circle opacity-70"><i class="fas fa-camera" /></button>
                    {!-- # TODO: For some reason, this hover:cursor-pointer isn't working on Edge but it works on Firefox. :( --}
                    <LiveFileInput upload={@uploads.header} class="h-8 w-8 opacity-0 hover:cursor-pointer z-40" />
                  </div>
                </div>
              </div>
            </div>
            <div class="relative w-24 h-20">
              <div class="absolute -top-4 left-6">
                <div class="relative flex justify-center items-center w-24">
                  <div class="avatar">
                    <div class="rounded-full w-24">
                      {#if Enum.empty?(@uploads.pfp.entries) && !@user.pfp_img_id}
                        <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
                      {#elseif !Enum.empty?(@uploads.pfp.entries)}
                        {Phoenix.LiveView.Helpers.live_img_preview(Enum.at(@uploads.pfp.entries, 0))}
                      {#elseif @user.pfp_img_id}
                        <img src={Routes.public_image_path(Endpoint, :image, @user.pfp_img_id)}>
                      {/if}
                    </div>
                  </div>
                  <div class="absolute top-8 left-8 w-8">
                    <div class="relative">
                      <button type="button" class="absolute top-0 left-0 btn btn-sm btn-circle opacity-70"><i class="fas fa-camera" /></button>
                      {!-- # TODO: For some reason, this hover:cursor-pointer isn't working on Edge but it works on Firefox. :( --}
                      <LiveFileInput upload={@uploads.pfp} class="h-8 w-8 opacity-0 hover:cursor-pointer z-40" />
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <TagsInput
              id="user_tags"
              label="Interests"
              info="Type to search for existing tags. Press Enter or Tab to add the tag. You can make it whatever you want as long as it's 100 characters or shorter."
              name={:tags}
            />
            <TextInput name={:name} icon="user" info="Your display name." opts={required: true} />
            <TextInput
              name={:handle}
              icon="at"
              info="Your handle that people can @ you with."
              opts={required: true}
            />
            <TextArea name={:bio} info="Tell us a little bit about yourself!" />
            <Submit label="Save" />
          </Form>
        </div>
      </div>
    </Layout>
    """
  end
end
