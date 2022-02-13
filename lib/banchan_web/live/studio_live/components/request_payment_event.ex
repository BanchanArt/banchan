defmodule BanchanWeb.StudioLive.Components.RequestPaymentEvent do
  @moduledoc """
  This is what shows up on the commission timeline when an artist asks for payment.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event

  alias Surface.Components.Form

  alias BanchanWeb.Components.{Avatar, UserHandle}
  alias BanchanWeb.Components.Form.{Submit, TextInput}

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
      {#case @event.payment_request && @event.payment_request.status}
        {#match :pending}
          TODO:
          <hr>
          <div class="p-4">
            {#if @current_user.id == @commission.client.id}
              Banchan holds all funds until both parties agree to pay out the balance (this can happen any time).
              <Form for={@changeset} change="change" submit="submit">
                <TextInput name={:amount} show_label={false} opts={placeholder: "Tip"} />
                <Submit changeset={@changeset} label="Pay" />
              </Form>
            {#else}
              Waiting for Payment
            {/if}
          </div>
        {#match :submitted}
          <hr>
          TODO: Show option to go back to payment session or cancel session here.
        {#match :canceled}
          <hr>
          TODO: Payment was canceled
        {#match :succeeded}
          <hr>
          <div class="p-4">
            TODO: Yay it's paid! Banchan will hold on to funds until the commission is completed.
          </div>
        {#match :paid_out}
          <hr>
          TODO: Funds have been paid out to the Studio.
        {#match nil}
          TODO: Please Wait...
      {/case}
    </div>
    """
  end
end
