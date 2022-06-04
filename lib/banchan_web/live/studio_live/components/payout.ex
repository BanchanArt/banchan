defmodule BanchanWeb.StudioLive.Components.Payout do
  @moduledoc """
  Individual Payout display component. Shows a list of invoices related to
  commissions that were paid out as part of this Payout.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.{LivePatch, LiveRedirect}

  alias Banchan.Studios
  alias Banchan.Studios.Payout

  alias BanchanWeb.Components.{Avatar, Button, UserHandle}

  prop studio, :struct, required: true
  prop payout, :struct, required: true
  prop data_pending, :boolean, default: false

  data modal_open, :boolean, default: false
  data cancel_pending, :boolean, default: false

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
     |> assign(cancel_pending: false)
     |> assign(assigns)}
  end

  def handle_event("toggle_modal", _, socket) do
    {:noreply, socket |> assign(modal_open: !socket.assigns.modal_open)}
  end

  def handle_event("close_modal", _, socket) do
    {:noreply, socket |> assign(modal_open: false)}
  end

  def handle_event("nothing", _, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_payout", _, socket) do
    Task.Supervisor.start_child(
      Banchan.TaskSupervisor,
      fn ->
        case Studios.cancel_payout(socket.assigns.studio, socket.assigns.payout.stripe_payout_id) do
          :ok ->
            send_update(
              __MODULE__,
              id: "payout",
              modal_open: false,
              add_flash: {:info, "Payout cancelled."}
            )

          {:error, err} ->
            send_update(
              __MODULE__,
              id: "payout",
              cancel_pending: false,
              modal_open: false,
              add_flash: {:error, "Failed to cancel payout: #{err.user_message}"}
            )
        end
      end,
      restart: :transient
    )

    {:noreply, socket |> assign(cancel_pending: true)}
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  def render(assigns) do
    cancel_disabled =
      !assigns.payout || assigns.cancel_pending || !assigns.payout.stripe_payout_id ||
        Payout.done?(assigns.payout)

    ~F"""
    <div class="flex flex-col">
      {!-- Cancellation modal --}
      <div
        class={"modal", "modal-open": @modal_open}
        :on-click="toggle_modal"
        :on-window-keydown="close_modal"
        phx-key="Escape"
      >
        <div :on-click="nothing" class="modal-box relative">
          <div class="btn btn-sm btn-circle absolute right-2 top-2" :on-click="close_modal">✕</div>
          <h3 class="text-lg font-bold">Confirm Cancellation</h3>
          <p class="py-4">Are you sure you want to cancel this payout? Note that the payout may have already completed (or failed).</p>
          <div class="modal-action">
            <Button
              disabled={!@modal_open || cancel_disabled}
              class={"cancel-payout btn-error", loading: @cancel_pending}
              click="cancel_payout"
            >Confirm</Button>
          </div>
        </div>
      </div>
      {!-- Header --}
      <h1 class="text-3xl pt-4 px-4">
        <LivePatch
          class="go-back md:hidden p-2"
          to={Routes.studio_payouts_path(Endpoint, :index, @studio.handle)}
        >
          <i class="fas fa-arrow-left text-2xl" />
        </LivePatch>
        Payout
        {#if !@data_pending}
          <div class="badge badge-secondary badge-lg">{Payout.humanize_status(@payout.status)}</div>
        {/if}
      </h1>
      <div class="divider" />
      {#if !@data_pending}
        <div class="flex flex-col px-4">
          {#if @data_pending}
            <i class="fas fa-spinner animate-spin" />
          {#else}
            <div class="text-3xl font-bold">{Money.to_string(@payout.amount)}</div>
          {/if}
          <h3
            class="text-xl"
            title={@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}
          >
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
            {@payout.inserted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}.
          </h3>
          <div class="text-xl">
            <div title={@payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>Expected arrival: {@payout.arrival_date |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}.</div>
            {#if @payout.failure_code}
              <div>Failure: {@payout.failure_message}</div>
            {/if}
          </div>
          <Button disabled={cancel_disabled} click="toggle_modal" class="open-modal modal-button btn-error">Cancel</Button>
        </div>
        <div class="divider">Invoices</div>
        <div class="menu divide-y-2 divide-neutral-content divide-opacity-10 pb-4">
          {#for invoice <- @payout.invoices}
            <a href={replace_fragment(
              Routes.commission_path(Endpoint, :show, invoice.commission.public_id),
              invoice.event
            )}>
              <div class="stats md:hidden">
                <div class="stat">
                  <div class="stat-title">
                    {invoice.commission.title}
                  </div>
                  <div class="stat-value">
                    {invoice.amount
                    |> Money.add(invoice.tip)
                    |> Money.subtract(invoice.platform_fee)
                    |> Money.to_string()}
                  </div>
                  <div class="stat-desc">
                    Net Amount
                  </div>
                </div>
              </div>
            </a>
          {/for}
        </div>
        <table class="text-md pt-4 px-4 hidden md:table w-full">
          <thead>
            <th>
              Commission
            </th>
            <th>
              Paid
            </th>
            <th>
              Net
            </th>
            <th>
              Invoiced
            </th>
            <th>
              Tip
            </th>
            <th>
              Fee
            </th>
          </thead>
          <tbody>
            {#for invoice <- @payout.invoices}
              <td class="text-lg">
                <LiveRedirect
                  class="link"
                  to={Routes.commission_path(Endpoint, :show, invoice.commission.public_id)}
                >{invoice.commission.title}</LiveRedirect>
                (<a
                  class="link"
                  href={replace_fragment(
                    Routes.commission_path(Endpoint, :show, invoice.commission.public_id),
                    invoice.event
                  )}
                >invoice</a>)
              </td>
              <td>
                {invoice.updated_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}
              </td>
              <td class="text-success">
                {invoice.amount
                |> Money.add(invoice.tip)
                |> Money.subtract(invoice.platform_fee)
                |> Money.to_string()}
              </td>
              <td>
                {Money.to_string(invoice.amount)}
              </td>
              <td>
                {Money.to_string(invoice.tip)}
              </td>
              <td>
                {Money.to_string(invoice.platform_fee)}
              </td>
            {/for}
          </tbody>
        </table>
      {#else}
        <i class="fas fa-spinner animate-spin text-3xl mx-auto grow" />
      {/if}
    </div>
    """
  end
end
