defmodule BanchanWeb.StudioLive.New do
  @moduledoc """
  New studio creation page.
  """
  use BanchanWeb, :surface_view

  import Slug
  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  alias Banchan.Studios
  alias Banchan.Studios.Studio

  alias BanchanWeb.Components.Form.{TextArea, TextInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket)
    changeset = Studio.changeset(%Studio{}, %{})
    {:ok, assign(socket, changeset: changeset)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">New Studio</h1>

      <div class="grid grid-cols-3 gap-4">
        <Form
          class="col-span-1"
          for={@changeset}
          change="change"
          submit="submit"
          opts={autocomplete: "off"}
        >
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
          <TextArea name={:description} opts={required: true} />
          <div class="field">
            <div class="control">
              <Submit
                class="btn btn-secondary text-center rounded-full py-1 px-5 m-1"
                label="Save"
                opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
              />
            </div>
          </div>
        </Form>
      </div>
    </Layout>
    """
  end

  @impl true
  def handle_event("change", %{"studio" => studio, "_target" => target}, socket) do
    studio =
      if target == ["studio", "name"] do
        %{studio | "handle" => slugify(studio["name"])}
      else
        studio
      end

    changeset =
      %Studio{}
      |> Studio.changeset(studio)
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Studios.new_studio(%Studio{artists: [socket.assigns.current_user]}, val["studio"]) do
      {:ok, studio} ->
        put_flash(socket, :info, "Profile updated")
        {:noreply, redirect(socket, to: Routes.studio_shop_path(Endpoint, :show, studio.handle))}

      other ->
        other
    end
  end
end
