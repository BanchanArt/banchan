defmodule BanchanWeb.CommissionLive.Components.CommentBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event
  alias Banchan.Repo
  alias Banchan.Uploads

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{
    MarkdownInput,
    Submit
  }

  prop commission, :struct, required: true
  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true

  data changeset, :struct
  data uploads, :map
  data studio, :struct

  def update(assigns, socket) do
    studio =
      if socket.assigns[:studio] && socket.assigns[:studio].id == assigns[:commission].studio_id do
        socket.assigns.studio
      else
        (assigns[:commission] |> Repo.preload(:studio)).studio
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(studio: studio)
     |> assign(changeset: Event.comment_changeset(%Event{}, %{}))
     |> allow_upload(:attachment,
       accept: :any,
       max_entries: 10,
       max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
     )}
  end

  def handle_event(
        "change",
        %{"event" => event},
        socket
      ) do
    changeset =
      %Event{}
      |> Event.comment_changeset(event)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event("add_comment", %{"event" => %{"text" => text}}, socket) do
    attachments = process_uploads(socket)

    case Commissions.add_comment(
           socket.assigns.current_user,
           socket.assigns.commission,
           socket.assigns.current_user_member?,
           attachments,
           text
         ) do
      {:ok, _event} ->
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

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_redirect(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}
    end
  end

  defp process_uploads(socket) do
    consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
      {:ok,
       Uploads.save_file!(
         socket.assigns.current_user,
         path,
         entry.client_type,
         entry.client_name
       )}
    end)
  end

  def render(assigns) do
    ~F"""
    <div id={@id} class="message-box">
      <Form for={@changeset} change="change" submit="add_comment" opts={id: @id <> "_form"}>
        <div class="block space-y-4">
          <MarkdownInput
            id={@id <> "_markdown_input"}
            name={:text}
            show_label={false}
            class="w-full"
            upload={@uploads.attachment}
            cancel_upload="cancel_upload"
          />
          <div class="flex flex-row-reverse">
            <Submit changeset={@changeset} class="w-full md:w-fit ml-auto" label="Post" />
          </div>
        </div>
      </Form>
    </div>
    """
  end
end
