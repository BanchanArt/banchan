defmodule BanchanWeb.DenizenLive.Edit do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts

  alias BanchanWeb.Components.Form.{Submit, TextArea, TextInput, UploadInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    user = Accounts.get_user_by_handle!(handle)

    {:ok,
     socket
     |> assign(user: user, changeset: User.profile_changeset(user))
     |> allow_upload(:pfp,
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

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Accounts.update_user_profile(socket.assigns.user, val["user"]) do
      {:ok, user} ->
        socket = assign(socket, changeset: User.profile_changeset(user), user: user)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_redirect(socket, to: Routes.denizen_show_path(Endpoint, :show, user.handle))}

      other ->
        other
    end
  end

  @impl true
  def handle_event("change_pfp", _, socket) do
    uploads = socket.assigns.uploads

    socket =
      Enum.reduce(uploads.pfp.entries, socket, fn entry, socket ->
        case upload_errors(uploads.pfp, entry) do
          [f | _] ->
            socket
            |> cancel_upload(:pfp, entry.ref)
            |> put_flash(
              :error,
              "File `#{entry.client_name}` upload failed: #{UploadInput.error_to_string(f)}"
            )

          [] ->
            socket
        end
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_pfp_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :pfp, ref)}
  end

  @impl true
  def handle_event("submit_pfp", _, socket) do
    consume_uploaded_entries(socket, :pfp, fn %{path: path}, _entry ->
      {:ok,
       Accounts.update_user_pfp(
         Accounts.get_user_by_handle!(socket.assigns.current_user.handle),
         path
       )}
    end)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} padding={0} current_user={@current_user} flashes={@flash}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <h1 class="text-2xl">Edit Profile for @{@user.handle}</h1>
          <Form class="profile-info" for={@changeset} change="change" submit="submit">
            <TextInput name={:name} icon="user" opts={required: true} />
            <TextInput name={:handle} icon="at" opts={required: true} />
            <TextArea name={:bio} />
            <Submit changeset={@changeset} label="Save" />
          </Form>
          <h2 class="text-xl">Update profile picture</h2>
          <Form class="pfp-upload" for={:pfp} change="change_pfp" submit="submit_pfp">
            <div class="mx-auto my-4 flex flex-row">
              <div class="avatar">
                <div class="rounded-full w-32">
                  {#if Enum.empty?(@uploads.pfp.entries) && !@user.pfp_img_id}
                    <img src={Routes.static_path(Endpoint, "/images/denizen_default_icon.png")}>
                  {#elseif !Enum.empty?(@uploads.pfp.entries)}
                    {Phoenix.LiveView.Helpers.live_img_preview(Enum.at(@uploads.pfp.entries, 0))}
                  {#elseif @user.pfp_img_id}
                    <img src={Routes.public_image_path(Endpoint, :image, @user.pfp_img_id)}>
                  {/if}
                </div>
              </div>
              <UploadInput label="Upload Profile Picture" upload={@uploads.pfp} cancel="cancel_pfp_upload" />
            </div>
            <Submit label="Upload" />
          </Form>
        </div>
      </div>
    </Layout>
    """
  end
end
