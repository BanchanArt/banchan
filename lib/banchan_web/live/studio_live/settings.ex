defmodule BanchanWeb.StudioLive.Settings do
  @moduledoc """
  Banchan studio profile viewing and editing.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Notifications
  alias Banchan.Studios
  alias Banchan.Studios.Studio

  alias BanchanWeb.CommissionLive.Components.StudioLayout
  alias BanchanWeb.Components.Button
  alias BanchanWeb.Components.Form.{Submit, TextArea, TextInput}

  import BanchanWeb.StudioLive.Helpers

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
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:settings}
      uri={@uri}
    >
      <div class="shadow bg-base-200 text-base-content">
        <div class="p-6">
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
          <Form class="col-span-one" for={@changeset} change="change" submit="submit">
            <TextInput name={:name} icon="user" opts={required: true} />
            {!-- # TODO: Bring this back when we've figured out how this interacts with Stripe --}
            {!-- <TextInput name={:handle} icon="at" opts={required: true} /> --}
            <TextArea name={:description} opts={required: true} />
            <TextArea name={:summary} />
            <TextArea name={:default_terms} />
            <TextArea name={:default_template} />
            <Submit changeset={@changeset} label="Save" />
          </Form>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
