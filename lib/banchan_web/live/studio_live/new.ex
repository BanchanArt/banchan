defmodule BanchanWeb.StudioLive.New do
  @moduledoc """
  New studio creation page.
  """
  use BanchanWeb, :surface_view

  import Slug
  alias Surface.Components.Form

  alias Banchan.Studios
  alias Banchan.Studios.Studio

  alias BanchanWeb.Components.Form.{Select, Submit, TextArea, TextInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(countries: [{:"Choose your country...", nil} | Studio.supported_countries()])

    if is_nil(socket.assigns.current_user.confirmed_at) do
      socket =
        put_flash(
          socket,
          :warning,
          "You must verify your email address before creating your own studio."
        )

      {:ok,
       push_redirect(socket,
         to: Routes.studio_index_path(Endpoint, :index)
       )}
    else
      changeset = Studio.creation_changeset(%Studio{}, %{})
      {:ok, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} current_user={@current_user} flashes={@flash}>
      <div class="shadow bg-base-200 text-base-content">
        <div class="p-6">
          <h1 class="text-2xl">New Studio</h1>
          <Form
            class="col-span-1"
            for={@changeset}
            change="change"
            submit="submit"
            opts={autocomplete: "off"}
          >
            <TextInput name={:name} icon="user" opts={required: true} />
            <TextInput name={:handle} icon="at" opts={required: true} />
            <TextArea name={:description} opts={required: true} />
            <Select name={:country} options={@countries} opts={required: true} />
            <Submit changeset={@changeset} label="Save" />
          </Form>
        </div>
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
      |> Studio.profile_changeset(studio)
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Studios.new_studio(
           %Studio{artists: [socket.assigns.current_user]},
           Routes.studio_shop_url(Endpoint, :show, val["studio"]["handle"]),
           val["studio"]
         ) do
      {:ok, studio} ->
        put_flash(socket, :info, "Profile updated")
        {:noreply, redirect(socket, to: Routes.studio_shop_path(Endpoint, :show, studio.handle))}

      other ->
        other
    end
  end
end
