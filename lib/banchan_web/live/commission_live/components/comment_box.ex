defmodule BanchanWeb.CommissionLive.Components.Commissions.CommentBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event
  alias Banchan.Utils

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{Checkbox, MarkdownInput, Submit, TextInput}

  prop commission, :struct, required: true
  prop actor, :struct, required: true
  prop current_user_member?, :boolean, required: true

  data changeset, :struct
  data uploads, :map

  def mount(socket) do
    {:ok,
     socket
     |> assign(changeset: Event.comment_changeset(%Event{}, %{}))
     # TODO: move max file size somewhere configurable.
     # TODO: constrain :accept?
     |> allow_upload(:attachment,
       accept: :any,
       max_entries: 10,
       max_file_size: 25_000_000
     )}
  end

  def handle_event("change", %{"event" => %{"amount" => amount} = event}, socket) do
    changeset =
      %Event{}
      |> Event.comment_changeset(%{event | "amount" => Utils.moneyfy(amount)})
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("change", %{"event" => event}, socket) do
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

  def handle_event("add_comment", %{"event" => %{"amount" => amount} = event}, socket)
      when amount != "" do
    attachments = process_uploads(socket)

    case Commissions.invoice(
           socket.assigns.actor,
           socket.assigns.commission,
           socket.assigns.current_user_member?,
           attachments,
           %{event | "amount" => Utils.moneyfy(amount)}
         ) do
      {:ok, _event} ->
        {:noreply,
         assign(socket,
           changeset: Event.comment_changeset(%Event{}, %{})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("add_comment", %{"event" => %{"text" => text}}, socket) do
    attachments = process_uploads(socket)

    case Commissions.add_comment(
           socket.assigns.actor,
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
    end
  end

  defp process_uploads(socket) do
    consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
      {:ok,
       Commissions.make_attachment!(
         socket.assigns.actor,
         path,
         entry.client_type,
         entry.client_name
       )}
    end)
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
            upload={@uploads.attachment}
            cancel_upload="cancel_upload"
            opts={required: true, placeholder: "Write a comment"}
          />
          {#if @current_user_member?}
            <TextInput name={:amount} show_label={false} opts={placeholder: "Invoice Amount (optional)"} />
            {#if Enum.empty?(@uploads.attachment.entries)}
              <Submit changeset={@changeset} label="Post" />
            {#else}
              <Checkbox name={:required} label="Require Payment to View Draft" />
              <Submit changeset={@changeset} label="Submit Draft" />
            {/if}
          {#else}
            <Submit changeset={@changeset} label="Post" />
          {/if}
        </div>
      </Form>
    </div>
    """
  end
end
