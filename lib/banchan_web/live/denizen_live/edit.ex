defmodule BanchanWeb.DenizenLive.Edit do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  alias Banchan.Accounts

  alias BanchanWeb.Components.Form.{TextArea, TextInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Accounts.get_user_by_handle!(handle)
    {:ok, assign(socket, user: user, changeset: User.profile_changeset(user))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <div class="card shadow bg-base-200 card-bordered text-base-content">
        <div class="card-body">
          <h1 class="text-2xl card-title">Edit Profile for @{@user.handle}</h1>
          <Form for={@changeset} change="change" submit="submit">
            <TextInput name={:name} wrapper_class="has-icons-left" opts={required: true}>
              <:right>
                <span class="icon is-small is-left">
                  <i class="fas fa-user" />
                </span>
              </:right>
            </TextInput>
            <TextInput name={:handle} wrapper_class="has-icons-left" opts={required: true}>
              <:right>
                <span class="icon is-small is-left">
                  <i class="fas fa-at" />
                </span>
              </:right>
            </TextInput>
            <TextArea name={:bio} opts={required: true} />
            <div class="field">
              <div class="control text-base-content m-1">
                <Submit
                  class="btn btn-secondary rounded-full py-1 px-5"
                  label="Save"
                  opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
                />
              </div>
            </div>
          </Form>
        </div>
      </div>
    </Layout>
    """
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
end
