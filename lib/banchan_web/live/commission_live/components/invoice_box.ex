defmodule BanchanWeb.CommissionLive.Components.InvoiceBox do
  @moduledoc """
  This is what shows up on the commission timeline when an artist asks for payment.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event
  alias Banchan.Utils

  alias Surface.Components.Form

  alias BanchanWeb.Components.Button
  alias BanchanWeb.Components.Form.{Submit, TextInput}

  prop current_user_member?, :boolean, required: true
  prop current_user, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true
  prop uri, :string, required: true

  # NOTE: We're not actually going to create an event directly. We're just
  # punning off this for the changeset validation.
  data changeset, :struct, default: %Event{} |> Event.amount_changeset(%{})

  data release_modal_open, :boolean, default: false

  data refund_modal_open, :boolean, default: false
  data refund_error_message, :string

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  @impl true
  def handle_event("change", %{"event" => %{"amount" => amount}}, socket) do
    changeset =
      %Event{}
      |> Event.amount_changeset(%{"amount" => Utils.moneyfy(amount)})
      |> Map.put(:action, :insert)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("submit", %{"event" => %{"amount" => amount}}, socket) do
    changeset =
      %Event{}
      |> Event.amount_changeset(%{"amount" => Utils.moneyfy(amount)})
      |> Map.put(:action, :insert)

    if changeset.valid? do
      url =
        Commissions.process_payment!(
          socket.assigns.current_user,
          socket.assigns.event,
          socket.assigns.commission,
          replace_fragment(socket.assigns.uri, socket.assigns.event),
          Utils.moneyfy(amount)
        )

      {:noreply, socket |> redirect(external: url)}
    else
      {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("continue_payment", _, socket) do
    uri = socket.assigns.event.invoice && socket.assigns.event.invoice.checkout_url

    if uri do
      {:noreply, socket |> redirect(external: uri)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("force_expire", _, socket) do
    Commissions.expire_payment!(socket.assigns.event.invoice, socket.assigns.current_user_member?)
    {:noreply, socket}
  end

  def handle_event(
        "refund",
        _,
        %{
          assigns: %{
            current_user: current_user,
            event: event,
            current_user_member?: current_user_member?
          }
        } = socket
      ) do
    case Commissions.refund_payment(
           current_user,
           event.invoice,
           current_user_member?
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(refund_modal_open: false, refund_error_message: nil)}

      {:error, %Stripe.Error{} = error} ->
        {:noreply,
         socket
         |> assign(refund_error_message: "Failed to refund payment: #{error.user_message}")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(refund_error_message: "Refund failed.")}
    end
  end

  def handle_event(
        "release",
        _,
        %{
          assigns: %{current_user: current_user, commission: commission, event: event}
        } = socket
      ) do
    Commissions.release_payment!(
      current_user,
      commission,
      event.invoice
    )

    {:noreply, socket |> assign(release_modal_open: false)}
  end

  def handle_event("toggle_release_modal", _, socket) do
    {:noreply, socket |> assign(release_modal_open: !socket.assigns.release_modal_open)}
  end

  def handle_event("close_release_modal", _, socket) do
    {:noreply, socket |> assign(release_modal_open: false)}
  end

  def handle_event("toggle_refund_modal", _, socket) do
    {:noreply,
     socket
     |> assign(refund_error_message: nil, refund_modal_open: !socket.assigns.refund_modal_open)}
  end

  def handle_event("close_refund_modal", _, socket) do
    {:noreply, socket |> assign(refund_error_message: nil, refund_modal_open: false)}
  end

  def handle_event("nothing", _, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="flex flex-col invoice-box">
      {!-- Refund confirmation modal --}
      {#if @refund_modal_open}
        <div
          class="modal modal-open"
          :on-click="toggle_refund_modal"
          :on-window-keydown="close_refund_modal"
          phx-key="Escape"
        >
          <div :on-click="nothing" class="modal-box relative">
            <div
              class="close-modal btn btn-sm btn-circle absolute right-2 top-2"
              :on-click="close_refund_modal"
            >✕</div>
            <h3 class="text-lg font-bold">Confirm Refund</h3>
            {#if @refund_error_message}
              <p class="alert alert-danger" role="alert">{@refund_error_message}</p>
            {/if}
            <p class="py-4">
              Are you sure you want to refund this payment?
              <p class="font-bold text-warning">
                WARNING: The Stripe portion of the platform fee can't be reimbursed, but Banchan's portion will be returned.
              </p>
            </p>
            <div class="modal-action">
              <Button disabled={!@refund_modal_open} class="refund-btn btn-warning" click="refund">Confirm</Button>
            </div>
          </div>
        </div>
      {/if}

      {!-- Release confirmation modal --}
      {#if @release_modal_open}
        <div
          class="modal modal-open"
          :on-click="toggle_release_modal"
          :on-window-keydown="close_release_modal"
          phx-key="Escape"
        >
          <div :on-click="nothing" class="modal-box relative">
            <div
              class="btn btn-sm btn-circle close-modal absolute right-2 top-2"
              :on-click="close_release_modal"
            >✕</div>
            <h3 class="text-lg font-bold">Confirm Fund Release</h3>
            <p class="py-4">Funds will be made available immediately to the studio, instead of waiting until the commission is approved. <p class="font-bold text-warning">WARNING: You will not be able to request a refund once released.</p></p>
            <div class="modal-action">
              <Button disabled={!@release_modal_open} class="release-btn btn-success" click="release">Confirm</Button>
            </div>
          </div>
        </div>
      {/if}

      {!-- Invoice box --}
      <div class="place-self-center stats stats-vertical md:stats-horizontal">
        <div class="stat">
          <div class="stat-title">Invoice</div>
          <div class="stat-value">{Money.to_string(@event.invoice.amount)}</div>
          {#case @event.invoice.status}
            {#match :pending}
              {#if @current_user.id == @commission.client_id}
                <div class="stat-desc">Payment is requested.</div>
                <Form for={@changeset} class="stat-actions" change="change" submit="submit">
                  <TextInput name={:amount} show_label={false} opts={placeholder: "Tip"} />
                  <Submit class="pay-invoice" changeset={@changeset} label="Pay" />
                  {#if @current_user_member?}
                    {!-- # TODO: This should be a Link so it's accessible. --}
                    <Button class="cancel-payment-request" click="force_expire" label="Cancel Payment Request" />
                  {/if}
                </Form>
              {#else}
                <div class="stat-desc">Waiting for Payment</div>
                {#if @current_user_member?}
                  <div class="stat-actions">
                    {!-- # TODO: This should be a Link so it's accessible. --}
                    <Button class="cancel-payment-request" click="force_expire" label="Cancel Payment Request" />
                  </div>
                {/if}
              {/if}
            {#match :submitted}
              <div class="stat-desc">Payment session in progress.</div>
              <div class="stat-actions">
                {#if @current_user.id == @commission.client_id}
                  {!-- # TODO: This should be a Link so it's accessible. --}
                  <Button class="continue-payment" click="continue_payment" label="Continue Payment" />
                {/if}
                {#if @current_user_member?}
                  {!-- # TODO: This should be a Link so it's accessible. --}
                  <Button class="cancel-payment-request" click="force_expire" label="Cancel Payment Request" />
                {/if}
              </div>
            {#match :expired}
              {!-- # TODO: Better, more obvious display for when something's expired --}
              <div class="stat-desc">Payment session expired.</div>
            {#match :succeeded}
              <div class="stat-desc">Payment succeeded.</div>
              <div class="stat-actions">
                {#if @current_user_member?}
                  <Button
                    label="Refund Payment"
                    click="toggle_refund_modal"
                    class="open-refund-modal modal-button btn-warning"
                  />
                {/if}
                {#if @current_user.id == @commission.client_id}
                  <Button
                    label="Release Now"
                    click="toggle_release_modal"
                    class="open-release-modal modal-button btn-success"
                  />
                {/if}
              </div>
            {#match :released}
              <div class="stat-desc">Payment released to studio.</div>
            {#match :refunded}
              {!-- # TODO: better, more obvious display for refunds... --}
              <div class="stat-desc">Payment has been refunded to the client.</div>
            {#match nil}
              {!-- NOTE: This state happens for a very brief window of time
                between when the payment request event is created, and when the
                Invoice itself is created, where there _is_ no
                Invoice for the event. If it's anything but a quick flash,
                there's probably a bug. --}
              <div class="stat-desc">Please wait...</div>
          {/case}
        </div>
        {#if @event.invoice.status == :succeeded || @event.invoice.status == :released ||
            @event.invoice.status == :refunded}
          <div class="stat">
            <div class="stat-title">Tip</div>
            <div class="stat-value">{Money.to_string(@event.invoice.tip)}</div>
            <div class="stat-desc">Thank you!</div>
          </div>
        {/if}
      </div>
      {#if !is_nil(@event.invoice.refund_status)}
        <span class="italic p-4 text-xs">
          {#case @event.invoice.refund_status}
            {#match :pending}
              A refund is pending for this payment.
            {#match :failed}
              Refund failed
              {#case @event.invoice.refund_failure_reason}
                {#match :lost_or_stolen_card}
                  due to a lost or stolen card.
                {#match :expired_or_canceled_card}
                  due to an expired or canceled card.
                {#match :unknown}
                  for an unknown reason. Please reach out to support.
              {/case}
            {#match :canceled}
              A refund was submitted but was canceled.
            {#match :requires_action}
              A refund was submitted but requires further action.
              {#if @current_user.id == @commission.client_id}
                Stripe will contact you for next steps, if they haven't already. Please check your email.
              {/if}
            {#match _}
          {/case}
        </span>
      {#elseif @event.invoice.status == :succeeded}
        <span class="italic p-4 text-xs">
          Note: Banchan.Art will hold all funds for this commission until a final draft is approved.
        </span>
      {#elseif @event.invoice.status == :released}
        <span class="italic p-4 text-xs">
          Note: Banchan.Art has released these funds to the studio for payout.
        </span>
      {/if}
    </div>
    """
  end
end
