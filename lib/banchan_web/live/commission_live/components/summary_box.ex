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
    Submit,
    TextInput
  }

  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission

  data currency, :atom
  data changeset, :struct
  data deposited, :struct
  data remaining, :struct
  data existing_open, :boolean
  data studio, :struct
  data open_final_invoice, :boolean, default: false
  data open_deposit_requested, :boolean, default: false
  data uploads, :map

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    if (socket.assigns.open_final_invoice || socket.assigns.open_deposit_requested) &&
         !socket.assigns.current_user_member? do
      raise "Only studio members can post invoices."
    end

    estimate = Commissions.line_item_estimate(assigns.commission.line_items)

    deposited =
      Commissions.deposited_amount(
        socket.assigns.current_user,
        socket.assigns.commission,
        socket.assigns.current_user_member?
      )

    remaining = Money.subtract(estimate, deposited)

    studio = (socket.assigns.commission |> Repo.preload(:studio)).studio

    existing_open = Payments.open_invoice(socket.assigns.commission) |> Repo.preload(:event)

    {:ok,
     socket
     |> assign(
       changeset: Event.invoice_changeset(%Event{}, %{}, remaining),
       currency: Enum.at(socket.assigns.commission.line_items, 0).amount.currency,
       studio: studio,
       existing_open: existing_open,
       remaining: remaining,
       deposited: deposited
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
       open_deposit_requested: false,
       changeset:
         Event.invoice_changeset(
           %Event{},
           %{},
           socket.assigns.remaining
         )
     )}
  end

  def handle_event("final_invoice", _, socket) do
    {:noreply,
     assign(
       socket,
       open_final_invoice: true,
       open_deposit_requested: false,
       changeset:
         Event.invoice_changeset(
           %Event{},
           %{"amount" => socket.assigns.remaining},
           socket.assigns.remaining
         )
     )}
  end

  def handle_event("request_deposit", _, socket) do
    {:noreply,
     assign(socket,
       open_deposit_requested: true,
       open_final_invoice: false
     )}
  end

  def handle_event("release_deposit", _, socket) do
    {:noreply,
     assign(socket,
       open_final_invoice: false,
       open_deposit_requested: false
     )}
  end

  def handle_event("change_deposit", %{"event" => %{"amount" => amount} = event}, socket) do
    change_invoice(
      Map.put(
        event,
        "amount",
        Utils.moneyfy(amount, Commissions.commission_currency(socket.assigns.commission))
      ),
      socket
    )
  end

  def handle_event("submit_deposit", %{"event" => %{"amount" => amount} = event}, socket) do
    submit_invoice(
      Map.put(
        event,
        "amount",
        Utils.moneyfy(amount, Commissions.commission_currency(socket.assigns.commission))
      ),
      socket
    )
  end

  def handle_event("change_final", %{"event" => event}, socket) do
    change_invoice(
      Map.put(
        event,
        "amount",
        Ecto.Changeset.fetch_field!(socket.assigns.changeset, :amount)
      ),
      socket
    )
  end

  def handle_event("submit_final", %{"event" => event}, socket) do
    submit_invoice(
      Map.put(
        event,
        "amount",
        Ecto.Changeset.fetch_field!(socket.assigns.changeset, :amount)
      ),
      socket,
      true
    )
  end

  def handle_event("release_deposits", _, socket) do
    Payments.release_all_deposits(socket.assigns.current_user, socket.assigns.commission)
    |> case do
      {:ok, _} ->
        IO.puts("Deposits released")
        Collapse.set_open(socket.assigns.id <> "-release-confirmation", false)
        {:noreply, socket}

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_navigate(to: ~p"/commissions/#{socket.assigns.commission.public_id}")}
    end
  end

  defp change_invoice(event, socket) do
    changeset =
      %Event{}
      |> Event.invoice_changeset(event, socket.assigns.remaining)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  defp submit_invoice(event, socket, final? \\ false) do
    attachments = process_uploads(socket)

    case Payments.invoice(
           socket.assigns.current_user,
           socket.assigns.commission,
           attachments,
           event,
           final?
         ) do
      {:ok, _event} ->
        {:noreply,
         assign(socket,
           changeset: Event.invoice_changeset(%Event{}, %{}),
           open_final_invoice: false,
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
    <div id={@id} class="rounded-lg bg-base-200 p-4 shadow-lg flex flex-col gap-2">
      {#if @open_final_invoice}
        <div class="text-lg font-medium pb-2">Final Invoice</div>
        <div class="text-sm">Attachments will be released on payment. All deposits will be immediately released, along with this payment, and the commission will be closed.</div>
        <Summary studio={@studio} line_items={@commission.line_items} show_options={false} />
        <div class="divider" />
        <BalanceBox
          id={@id <> "-balance-box"}
          deposited={@deposited}
          line_items={@commission.line_items}
          amount_due
        />
        <div class="divider" />
        <Form
          for={@changeset}
          change="change_final"
          submit="submit_final"
          id={"#{@id}-form"}
          opts={"phx-target": @myself}
        >
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
        <div class="text-lg font-medium pb-2">Partial Deposit</div>
        <div class="text-sm">Attachments will be released on payment. Deposit will be held until final invoice is submitted, or deposit is released early. by client.</div>
        <Summary studio={@studio} line_items={@commission.line_items} show_options={false} />
        <div class="divider" />
        <BalanceBox
          id={@id <> "-balance-box"}
          deposited={@deposited}
          line_items={@commission.line_items}
        />
        <Form
          for={@changeset}
          change="change_deposit"
          submit="submit_deposit"
          id={"#{@id}-form"}
          opts={"phx-target": @myself}
        >
          <div class="flex flex-row gap-2 items-center px-2">
            <div class="text-md font-medium">Deposit:</div>
            {Money.Currency.symbol(Commissions.commission_currency(@commission))}
            <TextInput name={:amount} show_label={false} opts={placeholder: "$12.34"} />
          </div>
          <div class="divider" />
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
      {#else}
        <div class="text-lg font-medium pb-2">Summary</div>
        <Collapse id={@id <> "-summary-details"} class="px-2">
          <:header><div class="font-medium">Details:</div></:header>
          <SummaryEditor
            id={@id <> "-summary-editor"}
            allow_edits={@current_user_member? && Commissions.commission_open?(@commission)}
            show_options={Commissions.commission_open?(@commission)}
          />
        </Collapse>
        <BalanceBox
          id={@id <> "-balance-box"}
          deposited={@deposited}
          line_items={@commission.line_items}
        />
        {#if @commission.status != :approved}
          <div class="input-group">
            {#if @current_user_member?}
              <Button
                disabled={@existing_open}
                click="request_deposit"
                class="btn-sm grow request-deposit"
                label="Request Deposit"
              />
              <Button
                disabled={@existing_open}
                click="final_invoice"
                class="btn-sm grow final-invoice"
                label="Final Invoice"
              />
            {/if}
          </div>
          {#if @current_user.id == @commission.client_id}
            {#if @existing_open}
              <Button disabled={@existing_open} class="btn-sm w-full" label="Release Deposits" />
            {#else}
              <Collapse
                id={@id <> "-release-confirmation"}
                show_arrow={false}
                class="grow rounded-lg my-2 bg-base-200"
              >
                <:header>
                  <button type="button" class="btn btn-primary btn-sm w-full">
                    Release Deposits
                  </button>
                </:header>
                <p>
                  All completed deposits will be <b class="font-bold">taken out of escrow</b> and sent to the studio, making them available for payout. You won't be able to ask for a refund from the studio for those invoices after this point.
                </p>
                <p class="py-2">Are you sure?</p>
                <Button click="release_deposits" class="btn-sm w-full" label="Confirm" />
              </Collapse>
            {/if}
          {/if}
          {#if @existing_open}
            <div>
              You can't take any further invoice actions until the <a class="link link-primary" href={"#event-#{@existing_open.event.public_id}"}>pending invoice</a> is handled.
            </div>
          {/if}
        {/if}
      {/if}
    </div>
    """
  end
end