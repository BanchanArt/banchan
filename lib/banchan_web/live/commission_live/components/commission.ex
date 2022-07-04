defmodule BanchanWeb.CommissionLive.Components.Commission do
  @moduledoc """
  Commission display for commission listing page
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LivePatch

  alias Banchan.Commissions
  alias Banchan.Commissions.Notifications

  alias BanchanWeb.Components.Collapse

  alias BanchanWeb.CommissionLive.Components.{
    BalanceBox,
    CommentBox,
    DraftBox,
    InvoiceModal,
    StatusBox,
    StudioBox,
    SummaryEditor,
    Timeline
  }

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true
  prop uri, :string, required: true

  prop subscribed?, :boolean
  prop archived?, :boolean

  data deposited, :struct

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    socket =
      socket
      |> assign(
        archived?: Commissions.archived?(socket.assigns.current_user, socket.assigns.commission),
        subscribed?:
          Notifications.user_subscribed?(socket.assigns.current_user, socket.assigns.commission),
        deposited:
          Commissions.deposited_amount(
            socket.assigns.current_user,
            socket.assigns.commission,
            socket.assigns.current_user_member?
          )
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("withdraw", _, socket) do
    {:ok, _} =
      Commissions.update_status(
        socket.assigns.current_user,
        socket.assigns.commission,
        "withdrawn"
      )

    Collapse.set_open(socket.assigns.id <> "-withdraw-confirmation", false)
    {:noreply, socket}
  end

  def handle_event("toggle_subscribed", _, socket) do
    if socket.assigns.subscribed? do
      Notifications.unsubscribe_user!(socket.assigns.current_user, socket.assigns.commission)
    else
      Notifications.subscribe_user!(socket.assigns.current_user, socket.assigns.commission)
    end

    {:noreply, assign(socket, subscribed?: !socket.assigns.subscribed?)}
  end

  def handle_event("toggle_archived", _, socket) do
    {:ok, _} =
      Commissions.update_archived(
        socket.assigns.current_user,
        socket.assigns.commission,
        !socket.assigns.archived?
      )

    {:noreply, assign(socket, archived?: !socket.assigns.archived?)}
  end

  def handle_event("open_invoice_modal", _, socket) do
    InvoiceModal.show(socket.assigns.id <> "-invoice-modal")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="relative">
      <h1 class="text-3xl pt-4 px-4 sticky top-16 bg-base-100 z-30 pb-2 border-b-2 border-base-content border-opacity-10 opacity-100">
        <LivePatch class="px-2 py-4" to={Routes.commission_path(Endpoint, :index)}>
          <i class="fas fa-arrow-left text-2xl" />
        </LivePatch>
        {@commission.title}
        {#if @archived?}
          <div class="badge badge-warning badge-lg">Archived</div>
        {/if}
      </h1>
      <div class="p-4">
        <div class="flex flex-col grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="flex flex-col md:col-span-2">
            <StudioBox
              commission={@commission}
              class="md:hidden rounded-box hover:bg-base-200 p-2 transition-all"
            />
            <div class="divider md:hidden" />
            <Timeline
              uri={@uri}
              commission={@commission}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
            />
            <div class="divider" />
            <div class="flex flex-col gap-4">
              <CommentBox
                id="comment-box"
                commission={@commission}
                current_user={@current_user}
                current_user_member?={@current_user_member?}
              />
            </div>
          </div>
          <div class="divider md:hidden" />
          <div class="flex flex-col">
            <StudioBox
              commission={@commission}
              class="hidden md:block rounded-box hover:bg-base-200 p-2 transition-all"
            />
            <div class="hidden md:flex md:divider" />
            <StatusBox
              id="action-box"
              commission={@commission}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
            />
            <div class="divider" />
            <div class="text-lg font-medium">Summary</div>
            <BalanceBox
              default_currency={@commission.studio.default_currency}
              deposited={@deposited}
              line_items={@commission.line_items}
            />
            <Collapse id="summary-details" class="px-2">
              <:header><div class="font-medium">Details:</div></:header>
              <SummaryEditor
                id="summary-editor"
                current_user={@current_user}
                current_user_member?={@current_user_member?}
                commission={@commission}
                allow_edits={@current_user_member?}
              />
            </Collapse>
            <button
              type="button"
              :if={@current_user_member?}
              :on-click="open_invoice_modal"
              class="btn btn-primary btn-sm w-full open-invoice-modal mt-2"
            >
              Send Invoice
            </button>
            <div class="divider" />
            <DraftBox
              id="draft-box"
              current_user={@current_user}
              current_user_member?={@current_user_member?}
              commission={@commission}
            />
            <div class="divider" />
            <div class="w-full">
              <div class="text-sm font-medium pb-2">Notifications</div>
              <button type="button" :on-click="toggle_subscribed" class="btn btn-sm w-full">
                {#if @subscribed?}
                  Unsubscribe
                {#else}
                  Subscribe
                {/if}
              </button>
            </div>
            <div class="divider" />
            <button type="button" :on-click="toggle_archived" class="btn btn-sm my-2 w-full">
              {#if @archived?}
                Unarchive
              {#else}
                Archive
              {/if}
            </button>
            {#if @current_user.id == @commission.client_id && @commission.status != :withdrawn}
              <Collapse id={@id <> "-withdraw-confirmation"} show_arrow={false} class="w-full my-2 bg-base-200">
                <:header>
                  <button type="button" class="btn btn-sm w-full">
                    Withdraw
                  </button>
                </:header>
                <p>
                  Your commission will be withdrawn and you won't be able to re-open it unless the studio does it for you.
                </p>
                <p class="py-2">Are you sure?</p>
                <button
                  disabled={@commission.status == :withdrawn || @current_user.id != @commission.client_id}
                  type="button"
                  :on-click="withdraw"
                  class="btn btn-sm btn-error my-2 w-full"
                >
                  Confirm
                </button>
              </Collapse>
            {/if}
          </div>
        </div>
      </div>
      {#if @current_user_member?}
        <InvoiceModal
          id={@id <> "-invoice-modal"}
          commission={@commission}
          current_user={@current_user}
          current_user_member?={@current_user_member?}
        />
      {/if}
    </div>
    """
  end
end
