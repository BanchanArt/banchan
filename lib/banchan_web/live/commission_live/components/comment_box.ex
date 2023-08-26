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

  alias BanchanWeb.Components.Avatar

  alias BanchanWeb.Components.Form.{
    QuillInput,
    Submit
  }

  prop commission, :struct, from_context: :commission
  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?

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
     |> assign(changeset: socket.assigns[:changeset] || Event.comment_changeset(%Event{}, %{}))
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
             Event.comment_changeset(
               %Event{},
               %{}
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_navigate(
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
      <Form for={@changeset} change="change" submit="add_comment" opts={"phx-target": @myself}>
        <div class="flex flex-row items-start w-full gap-4">
          <div class="hidden md:flex">
            <Avatar class="w-10 h-10" user={@current_user} />
          </div>
          <div class="grid w-full grid-cols-1 gap-4 grow">
            <QuillInput
              id={@id <> "_markdown_input"}
              name={:text}
              show_label={false}
              class="w-full"
              upload={@uploads.attachment}
              cancel_upload="cancel_upload"
            />
            <div class="flex flex-row">
              <Submit changeset={@changeset} class="w-full ml-auto md:w-fit" label="Post" />
            </div>
          </div>
        </div>
      </Form>
    </div>
    """
  end
end
