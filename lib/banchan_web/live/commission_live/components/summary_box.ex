defmodule BanchanWeb.CommissionLive.Components.SummaryBox do
  @moduledoc """
  General "summary" box for commission box, which also transforms into a final
  invoice box, or a request deposit box, as well as allowing clients to
  release deposits.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Payments
  alias Banchan.Payments.Invoice
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

  prop(current_user, :struct, from_context: :current_user)
  prop(current_user_member?, :boolean, from_context: :current_user_member?)
  prop(commission, :struct, from_context: :commission)
  prop(escrowed_amount, :struct, from_context: :escrowed_amount)
  prop(released_amount, :struct, from_context: :released_amount)

  data(currency, :atom)
  data(changeset, :struct)
  data(deposited, :struct)
  data(remaining, :struct)
  data(existing_open, :boolean)
  data(studio, :struct)
  data(open_final_invoice, :boolean, default: false)
  data(open_deposit_requested, :boolean, default: false)
  data(uploads, :map)
  data(minimum_release_amount, :struct, default: Payments.minimum_release_amount())
  data(can_release, :boolean, default: false)
  data(can_finalize, :boolean, default: false)

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
       changeset: Invoice.creation_changeset(%Invoice{}, %{}, remaining),
       currency: Commissions.commission_currency(socket.assigns.commission),
       studio: studio,
       existing_open: existing_open,
       remaining: remaining,
       deposited: deposited,
       can_finalize:
         Payments.cmp_money(
           socket.assigns.minimum_release_amount,
           estimate
         ) in [:lt, :eq],
       can_release:
         Payments.cmp_money(
           socket.assigns.minimum_release_amount,
           Money.add(socket.assigns.released_amount, socket.assigns.escrowed_amount)
         ) in [:lt, :eq]
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
         Invoice.creation_changeset(
           %Invoice{},
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
         Invoice.creation_changeset(
           %Invoice{amount: socket.assigns.remaining, deposited: socket.assigns.deposited},
           %{
             "line_items" =>
               Enum.map(
                 socket.assigns.commission.line_items,
                 &%{
                   "name" => &1.name,
                   "description" => &1.description,
                   "amount" => %{
                     "amount" => &1.amount.amount,
                     "currency" => &1.amount.currency
                   }
                 }
               )
           },
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

  def handle_event("change_deposit", %{"invoice" => %{"amount" => amount} = invoice}, socket) do
    change_invoice(
      Map.put(
        invoice,
        "amount",
        Utils.moneyfy(amount, Commissions.commission_currency(socket.assigns.commission))
      ),
      socket
    )
  end

  def handle_event("submit_deposit", %{"invoice" => %{"amount" => amount} = invoice}, socket) do
    submit_invoice(
      Map.put(
        invoice,
        "amount",
        Utils.moneyfy(amount, Commissions.commission_currency(socket.assigns.commission))
      ),
      socket
    )
  end

  def handle_event("change_final", %{"invoice" => invoice}, socket) do
    change_invoice(
      Map.put(
        invoice,
        "amount",
        Ecto.Changeset.fetch_field!(socket.assigns.changeset, :amount)
      ),
      socket
    )
  end

  def handle_event("submit_final", %{"invoice" => invoice}, socket) do
    submit_invoice(
      Map.put(
        invoice,
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
        Collapse.set_open(socket.assigns.id <> "-release-confirmation", false)
        {:noreply, socket}

      {:error, :release_under_threshold} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "You cannot release this commission's deposits because the total released amount would be under Banchan's minimum of #{Payments.convert_money(socket.assigns.minimum_release_amount, Commissions.commission_currency(socket.assigns.commission))}"
         )
         |> push_navigate(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_navigate(to: ~p"/commissions/#{socket.assigns.commission.public_id}")}
    end
  end

  defp change_invoice(invoice, socket) do
    changeset =
      %Invoice{}
      |> Invoice.creation_changeset(invoice, socket.assigns.remaining)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  defp submit_invoice(invoice, socket, final? \\ false) do
    attachments = process_uploads(socket)

    case Payments.invoice(
           socket.assigns.current_user,
           socket.assigns.commission,
           attachments,
           invoice,
           final?
         ) do
      {:ok, _event} ->
        {:noreply,
         assign(socket,
           changeset: Invoice.creation_changeset(%Invoice{}, %{}, socket.assigns.remaining),
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
            <TextInput name={:amount} show_label={false} />
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
        {#if Commissions.commission_open?(@commission) && Commissions.commission_active?(@commission)}
          <div class="input-group">
            {#if @current_user_member?}
              <Button
                disabled={@existing_open || !Commissions.commission_active?(@commission)}
                click="request_deposit"
                class="btn-sm grow request-deposit"
                label="Request Deposit"
              />
              <Button
                disabled={@existing_open || !Commissions.commission_active?(@commission) || !@can_finalize}
                click="final_invoice"
                class="btn-sm grow final-invoice"
                label="Final Invoice"
              />
            {/if}
          </div>
          {#if !@can_finalize}
            <p>You can't send a final invoice for this commission unless the subtotal is at least Banchan's commission minimum of {Payments.convert_money(@minimum_release_amount, Commissions.commission_currency(@commission))}. Add more options (or custom options) under "Details" until the threshold is reached.</p>
          {/if}
          {#if @current_user.id == @commission.client_id}
            {#if @existing_open || !Commissions.commission_active?(@commission) || !@can_release ||
                @deposited.amount == 0}
              <Button disabled class="btn-sm w-full" label="Release Deposits" />
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
            {#if !@can_release && @deposited.amount > 0}
              <p>
                You can't release any deposits until the total released deposits would
                add up to at least {Payments.convert_money(@minimum_release_amount, Commissions.commission_currency(@commission))
                |> Money.to_string()}.
              </p>
            {/if}
          {/if}
        {/if}
        {#if !Commissions.commission_open?(@commission)}
          <div>This commission is closed. You can't take any further actions on it unless it's reopened.</div>
        {#elseif !Commissions.commission_active?(@commission)}
          <div>Only open and accepted commissions can be invoiced. Accept the commission to continue.</div>
        {#elseif @existing_open}
          <div>
            You can't take any further invoice actions until the <a class="link link-primary" href={"#event-#{@existing_open.event.public_id}"}>pending invoice</a> is handled.
          </div>
        {/if}
      {/if}
    </div>
    """
  end
end
