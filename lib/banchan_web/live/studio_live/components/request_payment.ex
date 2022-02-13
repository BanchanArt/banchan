defmodule BanchanWeb.StudioLive.Components.Commissions.RequestPayment do
  @moduledoc """
  Box for requesting commission payments.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.PaymentRequest

  alias Surface.Components.Form

  alias BanchanWeb.Components.Card
  alias BanchanWeb.Components.Form.{Submit, TextInput}

  prop current_user, :struct, required: true
  prop commission, :struct, required: true

  data changeset, :struct, default: %PaymentRequest{} |> PaymentRequest.amount_changeset(%{})

  @impl true
  def handle_event("change", %{"payment_request" => %{"amount" => amount}}, socket) do
    changeset =
      %PaymentRequest{}
      |> PaymentRequest.amount_changeset(%{"amount" => moneyfy(amount)})
      |> Map.put(:action, :insert)

    {:noreply, socket |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("submit", %{"payment_request" => %{"amount" => amount}}, socket) do
    changeset =
      %PaymentRequest{}
      |> PaymentRequest.amount_changeset(%{"amount" => moneyfy(amount)})
      |> Map.put(:action, :insert)

    changeset =
      if changeset.valid? do
        Commissions.request_payment(
          socket.assigns.current_user,
          socket.assigns.commission,
          moneyfy(amount)
        )

        %PaymentRequest{} |> PaymentRequest.amount_changeset(%{})
      else
        changeset
      end

    {:noreply, socket |> assign(:changeset, changeset)}
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

  def render(assigns) do
    ~F"""
    <Card>
      <:header>
        Request Payment
      </:header>
      <Form for={@changeset} change="change" submit="submit">
        <TextInput name={:amount} show_label={false} opts={placeholder: "Amount"} />
        <Submit changeset={@changeset} label="Request Payment" />
      </Form>
    </Card>
    """
  end
end
