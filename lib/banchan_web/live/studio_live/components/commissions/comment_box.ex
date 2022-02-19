defmodule BanchanWeb.StudioLive.Components.Commissions.CommentBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{Checkbox, MarkdownInput, Submit, TextInput, UploadInput}

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
      |> Event.comment_changeset(%{event | "amount" => moneyfy(amount)})
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
           attachments,
           %{event | "amount" => moneyfy(amount)}
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

    case Commissions.create_event(
           :comment,
           socket.assigns.actor,
           socket.assigns.commission,
           attachments,
           %{"text" => text}
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

  defp moneyfy(amount) do
    # TODO: In the future, we can replace this :USD with a param and the DB will be fine.
    case Money.parse(amount, :USD) do
      {:ok, money} ->
        money

      :error ->
        amount
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
            opts={required: true, placeholder: "Write a comment"}
          />
          {#if @current_user_member?}
            <UploadInput label="Upload draft files" upload={@uploads.attachment} cancel="cancel_upload" />
          {#else}
            <UploadInput label="Upload attachments" upload={@uploads.attachment} cancel="cancel_upload" />
          {/if}
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
