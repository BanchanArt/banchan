defmodule BanchanWeb.CommissionLive.Components.Comment do
  @moduledoc """
  Component for commission page comments
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Payments
  alias Banchan.Repo

  alias Surface.Components.Form

  alias BanchanWeb.Components.{Button, Icon, Markdown, ReportModal, UserHandle}
  alias BanchanWeb.Components.Form.{QuillInput, Submit}
  alias BanchanWeb.CommissionLive.Components.{AttachmentBox, InvoiceBox}

  prop actor, :struct, required: true
  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission
  prop event, :struct, required: true
  prop uri, :string, from_context: :uri
  prop report_modal_id, :string, required: true

  data changeset, :struct

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp fmt_abs_time(time) do
    time |> Timex.to_datetime() |> Timex.format!("{RFC822}")
  end

  @impl true
  def update(params, socket) do
    socket = socket |> assign(params) |> assign(changeset: nil)
    socket = socket |> assign(event: socket.assigns.event)
    {:ok, socket}
  end

  @impl true
  def handle_event("edit", %{}, socket) do
    assigns = socket.assigns

    {:noreply,
     socket
     |> assign(
       changeset:
         (assigns.current_user_member? || assigns.current_user.id == assigns.actor.id ||
            :admin in assigns.current_user.roles || :mod in assigns.current_user.roles) &&
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
    case Commissions.update_event(socket.assigns.current_user, socket.assigns.event, event) do
      {:ok, event} ->
        {:noreply,
         socket
         |> assign(
           event: event |> Repo.preload([:attachments, :actor, :invoice]),
           changeset: nil
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_navigate(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to perform this action.")
         |> push_navigate(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}
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

    Commissions.delete_attachment(
      socket.assigns.current_user,
      socket.assigns.commission,
      socket.assigns.event,
      attachment
    )
    |> case do
      {:ok, _} ->
        {:noreply, socket}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "An internal error happened while trying to delete an attachment.")
         |> push_navigate(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}
    end
  end

  @impl true
  def handle_event("load_history", _, socket) do
    {:noreply,
     socket |> assign(event: socket.assigns.event |> Repo.preload(history: [:changed_by]))}
  end

  @impl true
  def handle_event("report", _, socket) do
    ReportModal.show(
      socket.assigns.report_modal_id,
      replace_fragment(socket.assigns.uri, socket.assigns.event)
    )

    {:noreply, socket}
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  def render(assigns) do
    ~F"""
    <div class="border rounded-lg bg-base-100 border-base-content border-opacity-10">
      <div class="flex flex-row items-center justify-between p-2 text-sm bg-opacity-50 border-b border-base-content border-opacity-10 bg-base-200">
        <div class="flex flex-row flex-wrap items-center gap-1 px-2 grow">
          <UserHandle user={@actor} />
          <span>
            <span class="opacity-75">
              {#if @event.invoice && @event.invoice.final}
                posted a final invoice
              {#elseif @event.invoice}
                posted a deposit invoice
              {#else}
                commented
              {/if}
            </span>
            <a
              title={"#{fmt_abs_time(@event.inserted_at)}"}
              class="opacity-75 hover:underline hover:opacity-100"
              href={replace_fragment(@uri, @event)}
            >{fmt_time(@event.inserted_at)}</a>
          </span>
          {#if @event.inserted_at != @event.updated_at}
            <div class="dropdown">
              <label :on-click="load_history" tabindex="0" class="text-xs italic hover:link">
                edited {fmt_time(@event.updated_at)}
              </label>
              <ol
                tabindex="0"
                class="p-1 border dropdown-content menu md:menu-compact bg-base-300 border-base-content border-opacity-10 rounded-xl"
              >
                {#if Ecto.assoc_loaded?(@event.history)}
                  {#for history <- @event.history}
                    <li class="block">
                      <div class="flex flex-col place-items-start">
                        <div>
                          Comment from {fmt_time(history.written_at)} changed by <UserHandle user={history.changed_by} />
                        </div>
                        {#if :mod in @current_user.roles || :admin in @current_user.roles}
                          <div class="font-bold">
                            Original Text:
                          </div>
                          <div>
                            <Markdown content={history.text} class="text-sm max-w-none" />
                          </div>
                        {/if}
                      </div>
                    </li>
                  {/for}
                {/if}
              </ol>
            </div>
          {/if}
        </div>
        <div class="dropdown dropdown-end">
          <label tabindex="0" class="btn btn-circle btn-ghost btn-xs">
            <Icon name="more-vertical" size="4" />
          </label>
          <ul
            tabindex="0"
            class="p-1 border dropdown-content menu md:menu-compact bg-base-300 border-base-content border-opacity-10 rounded-xl"
          >
            {#if !@changeset &&
                (@current_user_member? || @current_user.id == @actor.id || :admin in @current_user.roles ||
                   :mod in @current_user.roles)}
              <li>
                <button type="button" :on-click="edit">
                  <Icon name="pencil" size="4" label="edit" /> Edit
                </button>
              </li>
            {/if}
            <li>
              <button type="button" :on-click="report">
                <Icon name="flag" size="4" label="report" /> Report
              </button>
            </li>
          </ul>
        </div>
      </div>

      <div class="px-4 py-3 content user-markdown">
        {#if @changeset}
          <Form
            for={@changeset}
            change="change_edit"
            submit="submit_edit"
            opts={id: "editing-event-#{@event.public_id}"}
          >
            <QuillInput
              id={"editing-event-#{@event.public_id}"}
              name={:text}
              show_label={false}
              class="w-full"
            />
            <div class="flex flex-row-reverse">
              <Submit class="inline" label="Update" />
              <Button class="inline btn-error" click="cancel_edit">Cancel</Button>
            </div>
          </Form>
        {#else}
          <Markdown content={@event.text} class="text-sm max-w-none" />
        {/if}
      </div>

      {#if @event.invoice}
        <div :if={@event.text} class="divider" />
        <div class="pb-4">
          <InvoiceBox id={"invoice-box-#{@event.public_id}"} event={@event} />
        </div>
      {/if}

      {#if Enum.any?(@event.attachments)}
        <div :if={@event.text} class="divider" />
        <div class="px-4">
          <AttachmentBox
            base_id={@id <> "-attachments"}
            editing={!is_nil(@changeset)}
            attachments={@event.attachments}
            open_preview="open_preview"
            remove_attachment="remove_attachment"
            pending_payment={@event.invoice && @event.invoice.required && !Payments.invoice_paid?(@event.invoice)}
          />
        </div>
      {/if}
    </div>
    """
  end
end
