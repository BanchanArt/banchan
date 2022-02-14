defmodule BanchanWeb.StudioLive.Components.RequestPaymentEvent do
  @moduledoc """
  This is what shows up on the commission timeline when an artist asks for payment.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event

  alias Surface.Components.Form

  alias BanchanWeb.Components.{Avatar, Button, UserHandle}
  alias BanchanWeb.Components.Form.{Submit, TextInput}

  prop current_user_member?, :boolean, required: true
  prop current_user, :struct, required: true
  prop commission, :struct, required: true
  prop event, :struct, required: true
  prop uri, :string, required: true

  # NOTE: We're not actually going to create an event directly. We're just
  # punning off this for the changeset validation.
  data changeset, :struct, default: %Event{} |> Event.amount_changeset(%{})

  defp fmt_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  defp replace_fragment(uri, event) do
    URI.to_string(%{URI.parse(uri) | fragment: "event-#{event.public_id}"})
  end

  defp moneyfy(amount) do
    # TODO: In the future, we can replace this :USD with a param and the DB will be fine.
    case Money.parse(amount, :USD) do
      {:ok, money} ->
        money

      :error ->
        amount
    end
  end

  @impl true
  def handle_event("change", %{"event" => %{"amount" => amount}}, socket) do
    changeset =
      %Event{}
      |> Event.amount_changeset(%{"amount" => moneyfy(amount)})
      |> Map.put(:action, :insert)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("submit", %{"event" => %{"amount" => amount}}, socket) do
    changeset =
      %Event{}
      |> Event.amount_changeset(%{"amount" => moneyfy(amount)})
      |> Map.put(:action, :insert)

    if changeset.valid? do
      url =
        Commissions.process_payment!(
          socket.assigns.event,
          socket.assigns.commission,
          replace_fragment(socket.assigns.uri, socket.assigns.event),
          moneyfy(amount)
        )

      {:noreply, socket |> redirect(external: url)}
    else
      {:noreply, socket |> assign(:changeset, changeset)}
    end
  end

  @impl true
  def handle_event("continue_payment", _, socket) do
    uri =
      socket.assigns.event.payment_request && socket.assigns.event.payment_request.checkout_url

    if uri do
      {:noreply, socket |> redirect(external: uri)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("force_expire", _, socket) do
    Commissions.expire_payment!(socket.assigns.event.payment_request)
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="shadow-lg bg-base-200 rounded-box border-2">
      <div class="text-sm p-2 items-center flex">
        <div class="flex items-center space-x-1">
          <Avatar class="w-6" user={@event.actor} />
          <UserHandle user={@event.actor} />
          <span>requested payment of <span class="font-bold">{Money.to_string(@event.amount)}</span> <a class="hover:underline" href={replace_fragment(@uri, @event)}>{fmt_time(@event.inserted_at)}</a>.</span>
        </div>
      </div>
      {#if @event.payment_request}
        <hr>
        <div class="p-4">
          {#case @event.payment_request.status}
            {#match :pending}
              TODO:
              {#if @current_user.id == @commission.client.id}
                Banchan holds all funds until both parties agree to pay out the balance (this can happen any time).
                <Form for={@changeset} change="change" submit="submit">
                  <TextInput name={:amount} show_label={false} opts={placeholder: "Tip"} />
                  <Submit changeset={@changeset} label="Pay" />
                </Form>
              {#else}
                Waiting for Payment
              {/if}
              {#if @current_user_member?}
                <Button click="force_expire" label="Cancel Payment" />
              {/if}
            {#match :submitted}
              TODO:
              {#if @current_user.id == @commission.client.id}
                {!-- TODO: This should be a Link so it's accessible. --}
                <Button click="continue_payment" label="Continue Payment" />
              {#else}
                Waiting for Payment
              {/if}
              {#if @current_user_member?}
                <Button click="force_expire" label="Cancel Payment" />
              {/if}
            {#match :expired}
              TODO: Payment session has expired. Please request payment again.
            {#match :succeeded}
              TODO: Yay it's paid! Banchan will hold on to funds until the commission is completed.
              Tip: {Money.to_string(@event.payment_request.tip)}, Total Platform Fees: {Money.to_string(@event.payment_request.platform_fee)}, Total for Studio: {Money.subtract(
                Money.add(@event.payment_request.tip, @event.payment_request.amount),
                @event.payment_request.platform_fee
              )}
            {#match :paid_out}
              TODO: Funds have been paid out to the Studio.
            {#match nil}
              TODO: Please Wait...
          {/case}
        </div>
      {/if}
    </div>
    """
  end
end
