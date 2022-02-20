defmodule BanchanWeb.StudioLive.Components.Commissions.Comment do
  @moduledoc """
  Component for commission page comments
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Uploads

  alias Surface.Components.Form

  alias BanchanWeb.Components.{Avatar, Button, UserHandle}
  alias BanchanWeb.Components.Form.{MarkdownInput, Submit}
  alias BanchanWeb.StudioLive.Components.Commissions.{AttachmentBox, InvoiceBox, MediaPreview}

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop studio, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true
  prop uri, :string, required: true

  data changeset, :struct

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp fmt_md(md) do
    HtmlSanitizeEx.markdown_html(Earmark.as_html!(md || ""))
  end

  @impl true
  def update(params, socket) do
    {:ok, socket |> assign(params) |> assign(changeset: nil)}
  end

  @impl true
  def handle_event("open_preview", %{"key" => key, "bucket" => bucket}, socket) do
    MediaPreview.open(
      "preview-#{socket.assigns.event.public_id}",
      Uploads.get_upload!(bucket, key)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", %{}, socket) do
    assigns = socket.assigns

    {:noreply,
     socket
     |> assign(
       changeset:
         (assigns.current_user_member? || assigns.current_user.id == assigns.event.actor.id) &&
           Commissions.change_event_text(assigns.event, %{})
     )}
  end

  @impl true
  def handle_event("change_edit", %{"event" => event}, socket) do
    changeset =
      socket.assigns.event
      |> Commissions.change_event_text(event)
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit_edit", %{"event" => event}, socket) do
    case Commissions.update_event(socket.assigns.event, event) do
      {:ok, event} ->
        # TODO: broadcast + update elsewhere?
        {:noreply, socket |> assign(event: event, changeset: nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}
    end
  end

  @impl true
  def handle_event("cancel_edit", _, socket) do
    {:noreply, socket |> assign(changeset: nil)}
  end

  @impl true
  def handle_event("remove_attachment", %{"attachment-idx" => idx}, socket) do
    {index, ""} = Integer.parse(idx)
    attachment = Enum.fetch!(socket.assigns.event.attachments, index)
    Commissions.delete_attachment!(attachment)
    new_attachments = Enum.reject(socket.assigns.event.attachments, &(&1 == attachment))
    {:noreply, socket |> assign(event: %{socket.assigns.event | attachments: new_attachments})}
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  def render(assigns) do
    ~F"""
    <div class="shadow-md bg-base-200 rounded-box">
      <MediaPreview id={"preview-#{@event.public_id}"} commission={@commission} studio={@studio} />
      <div class="flex flex-row text-sm p-2">
        <div class="inline-flex grow items-baseline flex-wrap space-x-1">
          <div class="self-center">
            <Avatar class="w-6" user={@event.actor} />
          </div>
          <UserHandle user={@event.actor} />
          <span>
            {#if @event.invoice}
              posted an invoice
            {#else}
              commented
            {/if}
            <a class="hover:underline" href={replace_fragment(@uri, @event)}>{fmt_time(@event.inserted_at)}</a>.
          </span>
          {#if @event.inserted_at != @event.updated_at}
            <span class="text-xs italic">edited {fmt_time(@event.updated_at)}</span>
          {/if}
        </div>
        {#if !@changeset && (@current_user_member? || @current_user.id == @event.actor.id)}
          <button type="button" :on-click="edit" class="ml-auto hover:underline"><i class="fas fa-edit" /></button>
        {/if}
      </div>

      <div class="divider" />

      <div class="content px-4 user-markdown">
        {#if @changeset}
          {!-- # TODO: fix styling when in edit mode --}
          <Form for={@changeset} change="change_edit" submit="submit_edit">
            <MarkdownInput
              id={"editing-event-#{@event.public_id}"}
              name={:text}
              show_label={false}
              class="w-full"
            />
            <div class="flex">
              <Submit class="inline" label="Update" />
              <Button class="inline btn-secondary" click="cancel_edit">Cancel</Button>
            </div>
          </Form>
        {#else}
          {raw(fmt_md(@event.text))}
        {/if}
      </div>

      {#if Enum.any?(@event.attachments)}
        <div class="divider" />
        <div class="px-4">
          {#if @event.invoice && @event.invoice.required && !Commissions.invoice_paid?(@event.invoice)}
            Payment is required to view draft.
          {#else}
            <AttachmentBox
              editing={!is_nil(@changeset)}
              commission={@commission}
              studio={@studio}
              attachments={@event.attachments}
              open_preview="open_preview"
              remove_attachment="remove_attachment"
            />
          {/if}
        </div>
      {/if}

      {#if @event.invoice}
        <div class="divider" />
        <InvoiceBox
          id={"invoice-box-#{@event.public_id}"}
          current_user={@current_user}
          current_user_member?={@current_user_member?}
          uri={@uri}
          commission={@commission}
          event={@event}
        />
      {/if}
    </div>
    """
  end
end
