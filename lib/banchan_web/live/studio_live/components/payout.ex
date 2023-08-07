defmodule BanchanWeb.StudioLive.Components.Payout do
  @moduledoc """
  Individual Payout display component. Shows a list of invoices related to
  commissions that were paid out as part of this Payout.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias Banchan.Payments
  alias Banchan.Payments.Payout

  alias BanchanWeb.Components.{Avatar, Button, Modal, UserHandle}

  prop current_user, :struct, required: true
  prop studio, :struct, required: true
  prop payout, :struct, required: true
  prop data_pending, :boolean, default: false

  data modal_error_message, :any, default: nil

  def update(assigns, socket) do
    socket =
      case Map.get(assigns, :add_flash, nil) do
        {type, msg} ->
          socket |> put_flash(type, msg)

        nil ->
          socket
      end

    {:ok,
     socket
     |> assign(assigns)}
  end

  def handle_event("open_cancel_modal", _, socket) do
    Modal.show(socket.assigns.id <> "_cancel_modal")
    {:noreply, socket |> assign(modal_error_message: nil)}
  end

  def handle_event("cancel_payout", _, socket) do
    case Payments.cancel_payout(
           socket.assigns.current_user,
           socket.assigns.studio,
           socket.assigns.payout.stripe_payout_id
         ) do
      :ok ->
        Modal.hide(socket.assigns.id <> "_cancel_modal")
        {:noreply, socket}

      {:error, err} ->
        {:noreply,
         socket |> assign(modal_error_message: "Failed to cancel payout: #{err.user_message}")}
    end
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  defp status_color(status) do
    case status do
      :pending -> "bg-warning"
      :in_transit -> "bg-warning"
      :canceled -> "bg-error"
      :paid -> "bg-success"
      :failed -> "bg-error"
    end
  end

  def render(assigns) do
    cancel_disabled =
      !assigns.payout || !assigns.payout.stripe_payout_id ||
        Payout.done?(assigns.payout)

    ~F"""
    <div class="flex flex-col h-full bg-base-100 md:p-4 rounded-box md:rounded-bl-none overflow-hidden">
      {!-- Header --}
      <h1 class="px-4 pt-4 md:pt-0 md:px-0 text-3xl md:hidden border-b-2 border-neutral-content border-opacity-10 flex items-center gap-x-3">
        <LivePatch class="go-back p-2" to={~p"/studios/#{@studio.handle}/payouts"}>
          <i class="fas fa-arrow-left text-2xl" />
        </LivePatch>
        Payout
        {#if !@data_pending}
          <p class={
            "status bg-opacity-20 rounded-md whitespace-nowrap mt-0.5 px-1.5 py-0.5 text-xs font-medium ring-1 ring-inset",
            status_color(@payout.status)
          }>
            {Payout.humanize_status(@payout.status)}
          </p>
        {/if}
      </h1>
      {#if @data_pending}
        <div class="py-20 bg-base-100 w-full h-full flex flex-col items-center">
          <h2 class="sr-only">Loading...</h2>
          <i class="fas fa-spinner animate-spin text-3xl" />
        </div>
      {#else}
        <div class="p-4 bg-base-100">
          <div class="sm:flex sm:items-center">
            <div class="sm:flex-auto">
              <h1 class="text-3xl font-semibold leading-6">
                Total: <span class="text-success">{Payments.print_money(@payout.amount)}</span>
              </h1>
              <p class="mt-2 text-sm text-opacity-75">
                <div class="inline">
                  <div class="self-center inline">
                    Initiated by
                  </div>
                  <div class="self-center inline">
                    <Avatar user={@payout.actor} class="w-4" />
                  </div>
                  <div class="inline">
                    <UserHandle user={@payout.actor} />
                  </div>
                </div>
                <time dateTime={@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>{@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}</time>.
              </p>
              <p>
                Expected to arrive
                <time dateTime={@payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>{@payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}</time>.
              </p>
              {#if @payout.failure_code}
                <div>Failure: {@payout.failure_message}</div>
              {/if}
            </div>
            <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
              {#if !Payout.done?(@payout)}
                <Button
                  disabled={cancel_disabled}
                  click="open_cancel_modal"
                  class="open-modal open-cancel-modal modal-button btn-error btn-sm"
                >Cancel</Button>
              {/if}
            </div>
          </div>
          <div class="mt-8 flow-root">
            <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
              <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
                <div class="overflow-hidden shadow ring-1 ring-base-300 ring-opacity-5 sm:rounded-lg">
                  <table class="min-w-full divide-y divide-base-200">
                    <thead class="bg-base-300">
                      <tr>
                        <th
                          scope="col"
                          class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-base-content sm:pl-6"
                        >Commission</th>
                        <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-base-content">Net</th>
                        <th
                          scope="col"
                          class="px-3 py-3.5 text-left text-sm font-semibold text-base-content hidden md:table-cell"
                        >Invoiced</th>
                        <th
                          scope="col"
                          class="px-3 py-3.5 text-left text-sm font-semibold text-base-content hidden md:table-cell"
                        >Tip</th>
                        <th
                          scope="col"
                          class="px-3 py-3.5 text-left text-sm font-semibold text-base-content hidden md:table-cell"
                        >Fee</th>
                        <th
                          scope="col"
                          class="px-3 py-3.5 text-left text-sm font-semibold text-base-content hidden lg:table-cell"
                        >Invoiced At</th>
                        <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6">
                          <span class="sr-only">Invoice</span>
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-base-100 bg-base-200">
                      {#for invoice <- @payout.invoices}
                        <tr>
                          <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium sm:pl-6">
                            <LiveRedirect
                              class="text-primary hover:link"
                              to={Routes.commission_path(Endpoint, :show, invoice.commission.public_id)}
                            >{invoice.commission.title}</LiveRedirect>
                          </td>
                          <td>
                            <span class="text-success font-semibold">
                              {Payments.print_money(invoice.total_transferred)}
                            </span>
                            <dl class="md:hidden">
                              <dd class="mt-1 text-xs text-opacity-75 truncate">Fee: {Payments.print_money(invoice.platform_fee)}</dd>
                            </dl>
                          </td>
                          <td class="hidden md:table-cell font-semibold">
                            {Payments.print_money(invoice.amount)}
                          </td>
                          <td class="hidden md:table-cell font-semibold">
                            {Payments.print_money(invoice.tip)}
                          </td>
                          <td class="hidden md:table-cell font-semibold">
                            {Payments.print_money(invoice.platform_fee)}
                          </td>
                          <td class="hidden lg:table-cell">
                            <time dateTime={invoice.updated_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>{invoice.updated_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}</time>
                          </td>
                          <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6">
                            <a
                              class="text-secondary hover:link"
                              href={replace_fragment(
                                Routes.commission_path(Endpoint, :show, invoice.commission.public_id),
                                invoice.event
                              )}
                            >Invoice<span class="sr-only">
                                for {invoice.commission.title}</span></a>
                          </td>
                        </tr>
                      {/for}

                      <!-- More people... -->
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      {/if}
      {!-- Cancellation modal --}
      <Modal id={@id <> "_cancel_modal"}>
        <:title>Confirm Cancellation</:title>
        {#if @modal_error_message}
          <p class="alert alert-error" role="alert">{@modal_error_message}</p>
        {/if}
        Are you sure you want to cancel this payout? Note that the payout may have already completed (or failed).
        <:action>
          <Button class="cancel-payout btn-error" click="cancel_payout">Confirm</Button>
        </:action>
      </Modal>
    </div>
    """
  end
end
