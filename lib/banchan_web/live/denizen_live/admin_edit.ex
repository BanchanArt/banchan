defmodule BanchanWeb.DenizenLive.AdminEdit do
  @moduledoc """
  Admin-level user editing, such as changing roles, disabling, and such.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts

  alias BanchanWeb.Components.Form.{Submit, MarkdownInput, MultipleSelect}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    if :admin in socket.assigns.current_user.roles || :mod in socket.assigns.current_user.roles do
      user = Accounts.get_user_by_handle!(handle)

      {:ok,
       socket
       |> assign(
         user: user,
         roles: [Mod: :mod, Admin: :admin, Artist: :artist],
         changeset: User.admin_changeset(socket.assigns.current_user, user)
       )}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page.")
       |> push_redirect(to: Routes.denizen_show_path(Endpoint, :show, handle))}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.user
      |> User.admin_changeset(socket.assigns.current_user, val["user"])
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Accounts.update_admin_fields(socket.assigns.current_user, socket.assigns.user, val["user"]) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
      {:ok, user} ->
        {:noreply,
        socket
        |> put_flash(:info, "User updated.")
        |> push_redirect(to: Routes.denizen_show_path(Endpoint, :show, user.handle))}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} padding={0} current_user={@current_user} flashes={@flash}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Form class="profile-info" for={@changeset} change="change" submit="submit">
            <div class="text-xl">
              Manage User @{@user.handle}
            </div>
            <MultipleSelect info="User roles to apply to this user. Can select multiple items." name={:roles} options={@roles} />
            <MarkdownInput id="moderation_notes" info="These are internal notes for admins and moderators about this user. They are not displayed to the user or anyone else." name={:moderation_notes} />
            <Submit label="Save" changeset={@changeset} />
          </Form>
        </div>
      </div>
    </Layout>
    """
  end
end
