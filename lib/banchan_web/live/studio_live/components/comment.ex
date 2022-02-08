defmodule BanchanWeb.StudioLive.Components.Comment do
  @moduledoc """
  Component for commission page comments
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Uploads

  alias Surface.Components.Form

  alias BanchanWeb.Components.Button
  alias BanchanWeb.Components.Form.{MarkdownInput, Submit}
  alias BanchanWeb.StudioLive.Components.MediaPreview

  prop current_user, :struct, required: true
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

    # TODO: Use a more constrained changeset here that can only modify `text`.
    {:noreply,
     socket
     |> assign(
       changeset:
         assigns.current_user.id == assigns.event.actor.id &&
           Commissions.change_event(assigns.event, %{})
     )}
  end

  @impl true
  def handle_event("change_edit", %{"event" => event}, socket) do
    # TODO: Use a more constrained changeset here that can only modify `text`.
    changeset =
      socket.assigns.event
      |> Commissions.change_event(event)
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

  defp get_attachment_index(event, attachment) do
    Enum.find_index(event.attachments, &(&1 == attachment))
  end

  def render(assigns) do
    ~F"""
    <div class="shadow-lg bg-base-200 rounded-box border-2">
      <MediaPreview id={"preview-#{@event.public_id}"} commission={@commission} studio={@studio} />
      <div class="text-sm p-2">
        <a href={"/denizens/#{@event.actor.handle}"}>
          <img
            class="w-6 inline-block mask mask-circle"
            src={Routes.profile_image_path(Endpoint, :thumb, @event.actor.handle)}
          />
          <strong class="hover:underline">{@event.actor.handle}</strong></a>
        commented <a class="hover:underline" href={replace_fragment(@uri, @event)}>{fmt_time(@event.inserted_at)}</a>.
        {#if @event.inserted_at != @event.updated_at}
          <span class="text-xs italic">edited {fmt_time(@event.updated_at)}</span>
        {/if}
        {#if !@changeset && @current_user.id == @event.actor.id}
          <button type="button" :on-click="edit" class="float-right hover:underline">edit</button>
        {/if}
      </div>

      <hr>

      <div class="content p-4 user-markdown">
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
        <hr>
        <div class="p-4">
          <ul class="flex flex-wrap gap-4 p-2">
            {#for attachment <- Enum.filter(@event.attachments, & &1.thumbnail)}
              <li class="h-32 w-32">
                <button
                  class="relative"
                  :on-click="open_preview"
                  phx-value-key={attachment.upload.key}
                  phx-value-bucket={attachment.upload.bucket}
                >
                  {#if Uploads.video?(attachment.upload)}
                    <i class="fas fa-play text-4xl absolute top-10 left-10" />
                  {/if}
                  {#if @changeset}
                    <a
                      href="#"
                      :on-click="remove_attachment"
                      phx-value-attachment-idx={get_attachment_index(@event, attachment)}
                      class="-top-2 -right-2 absolute"
                    >
                      <i class="fas fa-times-circle text-2xl" />
                    </a>
                  {/if}
                  <img
                    alt={attachment.upload.name}
                    title={attachment.upload.name}
                    class="rounded-box"
                    src={Routes.commission_attachment_path(
                      Endpoint,
                      :thumbnail,
                      @studio.handle,
                      @commission.public_id,
                      attachment.upload.key
                    )}
                  />
                </button>
              </li>
            {/for}
          </ul>
          <div class="flex flex-col p-2">
            {#for attachment <- Enum.filter(@event.attachments, &(!&1.thumbnail))}
              <div class="relative">
                <a
                  class="relative"
                  target="_blank"
                  href={Routes.commission_attachment_path(
                    Endpoint,
                    :show,
                    @studio.handle,
                    @commission.public_id,
                    attachment.upload.key
                  )}
                >
                  <div title={attachment.upload.name} class="border-2 p-4 m-1">
                    <i class="float-right fas fa-file-download" /> <p class="truncate">{attachment.upload.name} ({attachment.upload.type})</p>
                  </div>
                </a>
                {#if @changeset}
                  <a
                    href="#"
                    :on-click="remove_attachment"
                    phx-value-attachment-idx={get_attachment_index(@event, attachment)}
                    class="-top-2 -right-2 absolute"
                  >
                    <i class="fas fa-times-circle text-2xl" />
                  </a>
                {/if}
              </div>
            {/for}
          </div>
        </div>
      {/if}
    </div>
    """
  end
end
