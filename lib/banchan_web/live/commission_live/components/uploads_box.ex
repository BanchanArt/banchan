defmodule BanchanWeb.CommissionLive.Components.UploadsBox do
  @moduledoc """
  Component for rendering the latest submitted draft on the commission page
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions

  alias BanchanWeb.CommissionLive.Components.AttachmentBox

  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission

  data attachments, :list
  data loaded, :boolean, default: false
  data previewing, :struct, default: nil

  def reload(id) do
    send_update(__MODULE__, id: id, reload: true)
  end

  def update(%{reload: true}, socket) do
    attachments = Commissions.list_attachments(socket.assigns.commission)

    {:ok, socket |> assign(attachments: attachments, loaded: true)}
  end

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
          socket |> assign(loaded: false)
        else
          socket
        end

      socket = socket |> assign(assigns)

      attachments = Commissions.list_attachments(socket.assigns.commission)

      {:ok, socket |> assign(attachments: attachments, loaded: true)}
    end
  end

  def render(assigns) do
    ~F"""
    <div>
      <div class="text-sm font-medium opacity-75">Uploads</div>
      {#if Enum.empty?(@attachments)}
        <div class="pt-4 text-sm">No uploads yet.</div>
      {#else}
        <AttachmentBox base_id={@id <> "-attachments"} attachments={@attachments} />
      {/if}
    </div>
    """
  end
end
