defmodule BanchanWeb.ProfileLive do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextInput}

  alias Banchan.Accounts
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(params, session, socket) do
    {:noreply, socket} = handle_params(params, session, socket)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Accounts.get_user_by_handle!(handle)
    {:noreply, assign(socket, user: user, changeset: User.profile_changeset(user))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      {#if @live_action == :index}
      Profile page for {@user.handle}
      <div>
        <p>Name: {@user.name}</p>
        <p>Bio: {@user.bio}</p>
      </div>
      {#else if @live_action == :edit && @user.id == @current_user.id}
      Editing profile for {@user.handle}
      <Form for={@changeset} change="change" submit="submit" opts={autocomplete: "off"}>
        <Field name={:handle}>
          <Label />
          <TextInput />
          <ErrorTag />
        </Field>
        <Field name={:name}>
          <Label />
          <TextInput />
          <ErrorTag />
        </Field>
        <Field name={:bio}>
          <Label />
          <TextInput />
          <ErrorTag />
        </Field>
        <Submit label="Save" opts={disabled: Enum.empty?(@changeset.changes) && !@changeset.valid?}/>
      </Form>
      {/if}
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
        put_flash(socket, :info, "Profile updated")
        {:noreply, push_patch(socket, to: Routes.profile_path(Endpoint, :edit, user.handle))}

      other ->
        other
    end
  end
end
