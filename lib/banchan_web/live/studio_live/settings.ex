defmodule BanchanWeb.StudioLive.Settings do
  @moduledoc """
  Banchan studio profile viewing and editing.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Studios
  alias Banchan.Studios.Studio

  alias BanchanWeb.Components.Form.{Submit, TextArea, TextInput}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.StudioLayout

  import BanchanWeb.StudioLive.Helpers

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(session, socket, true)
    socket = assign_studio_defaults(params, socket, true)
    {:ok, assign(socket, changeset: Studio.changeset(socket.assigns.studio, %{}))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:settings}
    >
      <h1 class="text-2xl">Edit Studio</h1>
      <h2 class="text-xl">{@studio.name}</h2>
      <div class="grid grid-cols-3 gap-4">
        <Form class="col-span-one" for={@changeset} change="change" submit="submit">
          <TextInput name={:name} icon="user" opts={required: true} />
          <TextInput name={:handle} icon="at" opts={required: true} />
          <TextArea name={:description} opts={required: true} />
          <Submit changeset={@changeset} label="Save" />
        </Form>
      </div>
    </StudioLayout>
    """
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.studio
      |> Studio.changeset(val["studio"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Studios.update_studio_profile(socket.assigns.studio, val["studio"]) do
      {:ok, studio} ->
        socket = assign(socket, changeset: Studio.changeset(studio, %{}), studio: studio)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_redirect(socket,
           to: Routes.studio_shop_path(Endpoint, :show, studio.handle)
         )}

      other ->
        other
    end
  end
end
