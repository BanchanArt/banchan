defmodule BanchanWeb.CommissionLive.Components.DraftBox do
  @moduledoc """
  Component for rendering the latest submitted draft on the commission page
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Uploads

  alias BanchanWeb.CommissionLive.Components.{AttachmentBox, MediaPreview}

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true

  data attachments, :list
  data loaded, :boolean, default: false
  data previewing, :struct, default: nil

  def update(assigns, socket) do
    current_comm = Map.get(socket.assigns, :commission)
    new_comm = Map.get(assigns, :commission)

    if socket.assigns.loaded &&
         current_comm &&
         new_comm &&
         current_comm.public_id == new_comm.public_id do
      socket = socket |> assign(assigns)
      {:ok, socket}
    else
      socket =
        if current_comm && (!new_comm || current_comm.public_id != new_comm.public_id) do
          Commissions.unsubscribe_from_commission_events(current_comm)
          socket |> assign(loaded: false)
        else
          socket
        end

      socket = socket |> assign(assigns)
      Commissions.subscribe_to_commission_events(socket.assigns.commission)

      event =
        Commissions.latest_draft(
          socket.assigns.current_user,
          socket.assigns.commission,
          socket.assigns.current_user_member?
        )

      {:ok, socket |> assign(attachments: event && event.attachments, loaded: true)}
    end
  end

  def handle_info(%{event: "new_events", payload: events}, socket) do
    if Enum.any?(events, &(&1.type == :comment && !Enum.empty?(&1.attachments))) do
      event =
        Commissions.latest_draft(
          socket.assigns.current_user,
          socket.assigns.commission,
          socket.assigns.current_user_member?
        )

      {:noreply, socket |> assign(attachments: event && event.attachments)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(%{event: "event_updated", payload: events}, socket) do
    if Enum.any?(events, &(&1.type == :comment && !Enum.empty?(&1.attachments))) do
      event =
        Commissions.latest_draft(
          socket.assigns.current_user,
          socket.assigns.commission,
          socket.assigns.current_user_member?
        )

      {:noreply, socket |> assign(attachments: event && event.attachments)}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_preview", %{"key" => key, "bucket" => bucket}, socket) do
    if socket.assigns.current_user.id == socket.assigns.commission.client_id ||
         socket.assigns.current_user_member? do
      MediaPreview.open(
        "draft-preview",
        Uploads.get_upload!(bucket, key)
      )
    end

    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div>
      {#if @attachments && !Enum.empty?(@attachments)}
        <h3 class="px-2 pb-2 text-xl">Latest Draft</h3>
        <MediaPreview id="draft-preview" commission={@commission} />
        <AttachmentBox commission={@commission} attachments={@attachments} open_preview="open_preview" />
      {#else}
        <h3 class="px-2 pb-2 text-xl">No Drafts Yet</h3>
      {/if}
    </div>
    """
  end
end
