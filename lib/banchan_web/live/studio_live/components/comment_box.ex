defmodule BanchanWeb.StudioLive.Components.Commissions.CommentBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{MarkdownInput, Submit}
  alias BanchanWeb.StudioLive.Components.AttachmentInput

  prop commission, :struct, required: true
  prop actor, :struct, required: true

  data changeset, :struct
  data uploads, :map

  def mount(socket) do
    {:ok,
     socket
     |> assign(
       changeset:
         Commissions.change_event(
           %Event{
             type: :comment
           },
           %{}
         )
     )
     # TODO: move max file size somewhere configurable.
     # TODO: constrain :accept?
     |> allow_upload(:attachment,
       accept: :any,
       max_entries: 10,
       max_file_size: 25_000_000
     )}
  end

  def handle_event("change", %{"event" => event}, socket) do
    changeset =
      %Event{
        type: :comment,
        actor: socket.assigns.actor,
        commission: socket.assigns.commission
      }
      |> Commissions.change_event(event)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event("add_comment", %{"event" => event}, socket) do
    attachments =
      consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
        {:ok,
         Commissions.make_attachment!(
           socket.assigns.actor,
           path,
           entry.client_type,
           entry.client_name
         )}
      end)

    case Commissions.create_event(
           :comment,
           socket.assigns.actor,
           socket.assigns.commission,
           attachments,
           event
         ) do
      {:ok, event} ->
        BanchanWeb.Endpoint.broadcast!(
          "commission:#{socket.assigns.commission.public_id}",
          "new_events",
          [event]
        )

        {:noreply,
         assign(socket,
           changeset:
             Commissions.change_event(
               %Event{
                 type: :comment
               },
               %{}
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="message-box">
      <Form for={@changeset} change="change" submit="add_comment">
        <div class="block space-y-4">
          <MarkdownInput
            id="initial-message"
            name={:text}
            show_label={false}
            class="w-full"
            opts={required: true, placeholder: "Here's what I'd like..."}
          />
          <AttachmentInput upload={@uploads.attachment} cancel="cancel_upload" />
          <Submit changeset={@changeset} label="Reply" />
        </div>
      </Form>
    </div>
    """
  end
end
