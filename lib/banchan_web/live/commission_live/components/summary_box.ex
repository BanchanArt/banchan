defmodule BanchanWeb.CommissionLive.Components.SummaryBox do
  @moduledoc """
  General "summary" box for commission box, which also transforms into a final
  invoice box, or a request deposit box, as well as allowing clients to
  release deposits.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event
  alias Banchan.Payments
  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Uploads
  alias Banchan.Utils

  alias Surface.Components.Form

  alias BanchanWeb.CommissionLive.Components.{
    Attachments,
    BalanceBox,
    Summary,
    SummaryEditor
  }

  alias BanchanWeb.Components.{Button, Collapse}

  alias BanchanWeb.Components.Form.{
    MarkdownInput,
    Submit
  }

  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission

  data currency, :atom
  data changeset, :struct
  data deposited, :struct
  data final_invoice, :struct
  data studio, :struct
  data open_final_invoice, :boolean, default: false
  data open_deposit_requested, :boolean, default: false
  data open_release_deposit, :boolean, default: false
  data uploads, :map

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    if (socket.assigns.open_final_invoice || socket.assigns.open_deposit_requested) &&
         !socket.assigns.current_user_member? do
      raise "Only studio members can post invoices."
    end

    if socket.assigns.open_release_deposit &&
         !socket.assigns.current_user.id != socket.assigns.commission.client_id do
      raise "Only clients can release deposits."
    end

    studio = (socket.assigns.commission |> Repo.preload(:studio)).studio

    final_invoice = Payments.final_invoice(socket.assigns.commission)

    {:ok,
     socket
     |> assign(
       changeset: Event.invoice_changeset(%Event{}, %{}),
       currency: Enum.at(socket.assigns.commission.line_items, 0).amount.currency,
       studio: studio,
       final_invoice: final_invoice && (final_invoice |> Repo.preload(:event)),
       deposited:
         Commissions.deposited_amount(
           socket.assigns.current_user,
           socket.assigns.commission,
           socket.assigns.current_user_member?
         )
     )
     |> allow_upload(:attachments,
       accept: :any,
       max_entries: 10,
       max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
     )}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachments, ref)}
  end

  def handle_event("cancel", _, socket) do
    {:noreply,
     assign(socket,
       open_final_invoice: false,
       open_request_deposit: false,
       open_release_deposit: false
     )}
  end

  def handle_event("final_invoice", _, socket) do
    {:noreply,
     assign(
       socket,
       open_final_invoice: true,
       open_request_deposit: false,
       open_release_deposit: false,
       changeset:
         Event.invoice_changeset(
           %Event{},
           %{
             "amount" =>
               socket.assigns.commission.line_items
               |> Enum.reduce(Money.new(0, socket.assigns.currency), fn x, acc ->
                 Money.add(x.amount, acc)
               end)
           }
         )
     )}
  end

  def handle_event("request_deposit", _, socket) do
    {:noreply,
     assign(socket,
       open_deposit_requested: true,
       open_final_invoice: false,
       open_release_deposit: false
     )}
  end

  def handle_event("release_deposit", _, socket) do
    {:noreply,
     assign(socket,
       open_release_deposit: true,
       open_final_invoice: false,
       open_deposit_requested: false
     )}
  end

  def handle_event(
        "change_deposit",
        %{"event" => %{"amount" => amount} = event},
        socket
      ) do
    changeset =
      %Event{}
      |> Event.invoice_changeset(%{
        event
        | "amount" => Utils.moneyfy(amount, socket.assigns.currency)
      })
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("change_final", %{"event" => event}, socket) do
    changeset =
      %Event{}
      |> Event.invoice_changeset(
        Map.put(
          event,
          "amount",
          Ecto.Changeset.fetch_field!(socket.assigns.changeset, :amount)
        )
      )
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("submit_final", %{"event" => event}, socket) do
    attachments = process_uploads(socket)

    case Payments.invoice(
           socket.assigns.current_user,
           socket.assigns.commission,
           attachments,
           Map.put(event, "amount", Ecto.Changeset.fetch_field!(socket.assigns.changeset, :amount)),
           true
         ) do
      {:ok, _event} ->
        {:noreply,
         assign(socket,
           changeset: Event.invoice_changeset(%Event{}, %{}),
           open_final_invoice: false,
           open_release_deposit: false,
           open_deposit_requested: false
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
    consume_uploaded_entries(socket, :attachments, fn %{path: path}, entry ->
      {:ok,
       Uploads.save_file!(socket.assigns.current_user, path, entry.client_type, entry.client_name)}
    end)
  end

  def render(assigns) do
    ~F"""
    <div class="rounded-lg bg-base-200 p-4 shadow-lg flex flex-col gap-2">
      {#if @open_final_invoice}
        <div class="text-lg font-medium pb-2">Final Invoice</div>
        <div class="text-sm">Attachments will be released on payment. Any previous deposits will be immediately released, along with this payment, and the commission will be closed.</div>
        <Summary studio={@studio} line_items={@commission.line_items} show_options={false} />
        <div class="divider" />
        <BalanceBox
          id={@id <> "-balance-box"}
          default_currency={Studios.default_currency(@commission.studio)}
          deposited={@deposited}
          line_items={@commission.line_items}
          amount_due
        />
        <div class="divider" />
        <Form for={@changeset} change="change_final" submit="submit_final" opts={id: "#{@id}-form"}>
          <div class="text-md font-medium">Attachments</div>
          <Attachments
            id={@id <> "-attachments"}
            upload={@uploads.attachments}
            cancel_upload="cancel_upload"
          />
          <div class="divider" />
          <MarkdownInput
            id={@id <> "-markdown-input"}
            name={:text}
            label="Invoice Text"
            info="Brief summary of what this invoice is meant to cover, for the record."
            class="w-full"
          />
          <div class="flex flex-row justify-end gap-2 pt-2">
            <Button click="cancel" class="btn-error" label="Cancel" />
            <Submit changeset={@changeset} class="grow" label="Send Invoice" />
          </div>
        </Form>
      {#elseif @open_deposit_requested}
      {#elseif @open_release_deposit}
      {#else}
        <div class="text-lg font-medium pb-2">Summary</div>
        <Collapse id={@id <> "-summary-details"} class="px-2">
          <:header><div class="font-medium">Details:</div></:header>
          <SummaryEditor id={@id <> "-summary-editor"} allow_edits={@current_user_member?} />
        </Collapse>
        <BalanceBox
          id={@id <> "-balance-box"}
          default_currency={Studios.default_currency(@commission.studio)}
          deposited={@deposited}
          line_items={@commission.line_items}
        />
        <div class="input-group">
          {#if @current_user_member?}
            <Button disabled={@final_invoice} click="request_deposit" class="btn-sm grow" label="Request Deposit" />
            <Button disabled={@final_invoice} click="final_invoice" class="btn-sm grow" label="Final Invoice" />
          {/if}
        </div>
        {#if @current_user.id == @commission.client_id}
          <Button disabled={@final_invoice} click="release_deposit" class="btn-sm grow" label="Release Deposit" />
        {/if}
        {#if @final_invoice}
          <div>
            You can't take any further invoice actions until the <a class="link link-primary" href={"#event-#{@final_invoice.event.public_id}"}>pending final invoice</a> is handled.
          </div>
        {/if}
      {/if}
    </div>
    """
  end
end
