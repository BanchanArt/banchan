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
    AddonPicker,
    Attachments,
    BalanceBox,
    Summary,
    SummaryEditor
  }

  alias BanchanWeb.Components.{Button, Collapse}

  alias BanchanWeb.Components.Form.{
    QuillInput,
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
  data(final_invoice, :struct)
  data(existing_open, :boolean)
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

    existing_open = Payments.open_invoice(socket.assigns.commission) |> Repo.preload(:event)

    final_invoice = Payments.final_invoice(socket.assigns.commission)

    {:ok,
     socket
     |> assign(
       changeset: Invoice.creation_changeset(%Invoice{}, %{}, remaining),
       currency: Commissions.commission_currency(socket.assigns.commission),
       existing_open: existing_open,
       remaining: remaining,
       deposited: deposited,
       final_invoice: final_invoice,
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
                   },
                   "multiple" => &1.multiple,
                   "count" => &1.count
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
      invoice
      |> Map.put(
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
      invoice
      |> Map.put(
        "amount",
        Ecto.Changeset.fetch_field!(socket.assigns.changeset, :amount)
      ),
      socket,
      true
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

  defp change_invoice(invoice, socket, final? \\ false) do
    changeset =
      %Invoice{deposited: socket.assigns.deposited, final: final?}
      |> Invoice.creation_changeset(
        invoice
        |> Map.put(
          "line_items",
          Enum.map(
            socket.assigns.commission.line_items,
            &%{
              "name" => &1.name,
              "description" => &1.description,
              "amount" => %{
                "amount" => &1.amount.amount,
                "currency" => &1.amount.currency
              },
              "multiple" => &1.multiple,
              "count" => &1.count
            }
          )
        ),
        socket.assigns.remaining
      )
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
    <div id={@id} class="flex flex-col gap-4">
      {#if @open_final_invoice}
        <div class="pb-2 text-lg font-medium opacity-100">Final Invoice</div>
        <div class="text-sm">Attachments will be released on payment. All deposits will be immediately released, along with this payment, and the commission will be closed.</div>
        <div class="grid grid-cols-1 gap-4 p-4 border rounded-lg border-base-content border-opacity-10 bg-base-100">
          <Summary line_items={@commission.line_items} />
          <div class="m-0 divider h-fit" />
          <BalanceBox
            id={@id <> "-balance-box"}
            deposited={@deposited}
            line_items={@commission.line_items}
            invoiced={@remaining}
          />
        </div>
        <div class="m-0 divider h-fit" />
        <Form
          for={@changeset}
          change="change_final"
          submit="submit_final"
          id={"#{@id}-form"}
          opts={"phx-target": @myself}
        >
          <div class="grid grid-cols-1 gap-4">
            <div class="text-base font-medium">Attachments</div>
            <Attachments
              id={@id <> "-attachments"}
              upload={@uploads.attachments}
              cancel_upload="cancel_upload"
            />
            <div class="m-0 divider h-fit" />
            <QuillInput
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
          </div>
        </Form>
      {#elseif @open_deposit_requested}
        <div class="pb-2 text-lg font-medium opacity-100">Partial Deposit</div>
        <div class="text-sm">Attachments will be released on payment. Deposit will be held until final invoice is submitted, or deposit is released early. by client.</div>
        <div class="grid grid-cols-1 gap-4 p-4 border rounded-lg border-base-content border-opacity-10 bg-base-100">
          <Summary line_items={@commission.line_items} />
          <div class="m-0 divider h-fit" />
          <BalanceBox
            id={@id <> "-balance-box"}
            deposited={@deposited}
            line_items={@commission.line_items}
          />
        </div>
        <div class="m-0 divider h-fit" />
        <Form
          for={@changeset}
          change="change_deposit"
          submit="submit_deposit"
          id={"#{@id}-form"}
          opts={"phx-target": @myself}
        >
          <div class="grid grid-cols-1 gap-4">
            <div class="text-sm font-medium opacity-75">Request Amount</div>
            <div class="flex flex-row items-center gap-2">
              {Payments.currency_symbol(Commissions.commission_currency(@commission))}
              <div class="grow">
                <TextInput name={:amount} show_label={false} />
              </div>
            </div>
            <div class="text-xs opacity-75">Deposits will be held until final invoice is submitted, or unless they are released early by the client.</div>
            <div class="m-0 divider h-fit" />
            <div class="text-base font-medium">Attachments</div>
            <Attachments
              id={@id <> "-attachments"}
              upload={@uploads.attachments}
              cancel_upload="cancel_upload"
            />
            <div class="m-0 divider h-fit" />
            <QuillInput
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
          </div>
        </Form>
      {#else}
        <div class="text-sm font-medium opacity-75">Order</div>
        <div class="grid grid-cols-1 gap-4 p-4 border rounded-lg border-base-content border-opacity-10 bg-base-100">
          <SummaryEditor
            id={@id <> "-summary-editor"}
            allow_edits={@current_user_member? && Commissions.commission_open?(@commission)}
          />
          <div class="m-0 divider h-fit" />
          <BalanceBox
            id={@id <> "-balance-box"}
            deposited={@deposited}
            line_items={@commission.line_items}
            tipped={@final_invoice && @final_invoice.tip}
          />
        </div>
        <div class="m-0 divider h-fit" />
        {#if @commission.offering}
          <div class="text-sm font-medium opacity-75">Available Add-ons</div>
          <div class="text-xs">Only the studio can add these to the commission.</div>
          <div class="grid grid-cols-1 gap-4 p-4 border rounded-lg border-base-content border-opacity-10 bg-base-100">
            <AddonPicker
              id={@id <> "-addon-picker"}
              allow_edits={@current_user_member? && Commissions.commission_open?(@commission)}
              allow_custom
            />
          </div>
          <div class="m-0 divider h-fit" />
        {/if}
        <div class="flex flex-col gap-4">
          <div class="text-sm font-medium opacity-75">Actions</div>
          {#if Commissions.commission_open?(@commission) && Commissions.commission_active?(@commission)}
            {#if @current_user_member?}
              <div class="flex flex-row items-center w-full gap-4">
                <Button
                  disabled={@existing_open || !Commissions.commission_active?(@commission) || @remaining.amount <= 0}
                  click="request_deposit"
                  class="btn-sm grow request-deposit"
                  label="Request Deposit"
                />
                <Button
                  disabled={@existing_open || !Commissions.commission_active?(@commission) || !@can_finalize ||
                    @remaining.amount < 0}
                  click="final_invoice"
                  class="btn-sm btn-secondary grow final-invoice"
                  label="Final Invoice"
                />
              </div>
              {#if !@can_finalize}
                <p>You can't send a final invoice for this commission unless the subtotal is at least Banchan's commission minimum of {Payments.convert_money(@minimum_release_amount, Commissions.commission_currency(@commission))}. Add more options (or custom options) under "Options" until the threshold is reached.</p>
              {/if}
              {#if @remaining.amount < 0}
                <p class="text-base font-semibold text-error">
                  Your commission's balance is negative.
                </p>
                <p>
                  You likely removed options since the last deposit was made. You must add new options to the commission
                  or reimburse one or more deposits to make the balance positive before you can invoice again.
                </p>
              {/if}
            {/if}
            {#if @current_user.id == @commission.client_id}
              {#if @existing_open || !Commissions.commission_active?(@commission) || !@can_release ||
                  @deposited.amount == 0}
                <Button disabled class="w-full btn-sm" label="Release Deposits" />
              {#else}
                <Collapse
                  id={@id <> "-release-confirmation"}
                  show_arrow={false}
                  class="my-2 rounded-lg grow bg-base-200"
                >
                  <:header>
                    <button type="button" class="w-full btn btn-primary btn-sm">
                      Release Deposits
                    </button>
                  </:header>
                  <p class="py-2">Are you sure?</p>
                  <Button click="release_deposits" class="w-full btn-sm" label="Confirm" />
                </Collapse>
                <p>
                  Upon release, all completed deposits will be <b class="font-bold">taken out of escrow</b> and sent to the studio. You won't be able to ask for a refund from the studio afterwards.
                </p>
              {/if}
              {#if !@can_release && @deposited.amount > 0}
                <p>
                  You can't release any deposits until the total released deposits would
                  add up to at least {Payments.convert_money(@minimum_release_amount, Commissions.commission_currency(@commission))
                  |> Payments.print_money()}.
                </p>
              {/if}
              {#if @existing_open && @deposited.amount > 0}
                <p>You can't release any deposits until the <a class="link link-primary" href={"#event-#{@existing_open.event.public_id}"}>pending invoice</a> is paid.</p>
              {/if}
            {/if}
          {/if}
          {#if @current_user_member?}
            {#if !Commissions.commission_open?(@commission)}
              <div>This commission is closed. You can't take any further actions on it.</div>
            {#elseif !Commissions.commission_active?(@commission)}
              <div>Only open and accepted commissions can be invoiced. Accept the commission by changing the status to "Accepted" below to continue.</div>
            {#elseif @existing_open}
              <div>
                You can't take any further invoice actions until the <a class="link link-primary" href={"#event-#{@existing_open.event.public_id}"}>pending invoice</a> is paid.
              </div>
            {/if}
          {/if}
        </div>
      {/if}
    </div>
    """
  end
end
