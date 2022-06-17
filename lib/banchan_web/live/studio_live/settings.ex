defmodule BanchanWeb.StudioLive.Settings do
  @moduledoc """
  Banchan studio profile viewing and editing.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Studios
  alias Banchan.Studios.{Notifications, Studio}

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.Button
  alias BanchanWeb.Components.Form.{MarkdownInput, Submit, TextArea, TextInput}
  alias BanchanWeb.StudioLive.Components.StudioLayout

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    {:ok,
     assign(socket,
       changeset: Studio.profile_changeset(socket.assigns.studio, %{}),
       subscribed?:
         Notifications.user_subscribed?(socket.assigns.current_user, socket.assigns.studio)
     )}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("toggle_subscribed", _, socket) do
    if socket.assigns.subscribed? do
      Notifications.unsubscribe_user!(socket.assigns.current_user, socket.assigns.studio)
    else
      Notifications.subscribe_user!(socket.assigns.current_user, socket.assigns.studio)
    end

    {:noreply, assign(socket, subscribed?: !socket.assigns.subscribed?)}
  end

  def handle_event("submit", val, socket) do
    case Studios.update_studio_profile(
           socket.assigns.studio,
           socket.assigns.current_user_member?,
           val["studio"]
         ) do
      {:ok, studio} ->
        socket = assign(socket, changeset: Studio.profile_changeset(studio, %{}), studio: studio)
        socket = put_flash(socket, :info, "Profile updated")
        {:noreply, socket}

      other ->
        other
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
  def render(assigns) do
    ~F"""
    <StudioLayout
      id="studio-layout"
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:settings}
      padding={0}
      uri={@uri}
    >
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <h1 class="text-2xl">{@studio.name}</h1>
          <div class="divider" />
          <h2 class="text-xl py-6">Notifications</h2>
          <div class="pb-6">Manage default notification settings for this studio. For example, whether to receive notifications for new commission requests.</div>
          <Button click="toggle_subscribed">
            {#if @subscribed?}
              Unsubscribe
            {#else}
              Subscribe
            {/if}
          </Button>
          <div class="divider" />
          <h2 class="text-xl py-6">Edit Studio Profile</h2>
          <Form class="flex flex-col gap-2" for={@changeset} change="change" submit="submit">
            <TextInput name={:name} icon="user" opts={required: true} />
            {!-- # TODO: Bring this back when we've figured out how this interacts with Stripe --}
            {!-- <TextInput name={:handle} icon="at" opts={required: true} /> --}
            <TextArea name={:description} opts={required: true} />
            <MarkdownInput id="summary" name={:summary} />
            <MarkdownInput id="default-terms" name={:default_terms} />
            <MarkdownInput id="default-template" name={:default_template} />
            <Submit changeset={@changeset} label="Save" />
          </Form>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
