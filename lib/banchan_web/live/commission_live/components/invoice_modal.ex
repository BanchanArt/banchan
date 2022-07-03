defmodule BanchanWeb.CommissionLive.Components.InvoiceModal do
  @moduledoc """
  Modal pop-up for posting invoices.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Label}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Commissions
  alias Banchan.Commissions.Event
  alias Banchan.Repo
  alias Banchan.Utils

  alias BanchanWeb.Components.Modal

  alias BanchanWeb.Components.Form.{
    Checkbox,
    HiddenInput,
    MarkdownInput,
    Select,
    Submit,
    TextInput
  }

  prop commission, :struct, required: true
  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true

  data changeset, :struct
  data uploads, :map
  data studio, :struct

  def show(modal_id) do
    Modal.show(modal_id <> "_inner_modal")
  end

  def hide(modal_id) do
    Modal.hide(modal_id <> "_inner_modal")
  end

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    if !socket.assigns.current_user_member? do
      raise "Invoice modal should only be displayed for studio members."
    end

    studio =
      if socket.assigns[:studio] && socket.assigns[:studio].id == assigns[:commission].studio_id do
        socket.assigns.studio
      else
        (assigns[:commission] |> Repo.preload(:studio)).studio
      end

    {:ok,
     socket
     |> assign(studio: studio)
     |> assign(changeset: Event.invoice_changeset(%Event{}, %{}))
     # TODO: move max file size somewhere configurable.
     # TODO: constrain :accept?
     |> allow_upload(:attachment,
       accept: :any,
       max_entries: 10,
       max_file_size: 25_000_000
     )}
  end

  def handle_event(
        "change",
        %{"event" => %{"amount" => amount, "currency" => currency} = event},
        socket
      ) do
    changeset =
      %Event{}
      |> Event.invoice_changeset(%{event | "amount" => Utils.moneyfy(amount, currency)})
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event(
        "submit",
        %{"event" => %{"amount" => amount, "currency" => currency} = event},
        socket
      )
      when amount != "" do
    attachments = process_uploads(socket)

    case Commissions.invoice(
           socket.assigns.current_user,
           socket.assigns.commission,
           socket.assigns.current_user_member?,
           attachments,
           %{event | "amount" => Utils.moneyfy(amount, currency)}
         ) do
      {:ok, _event} ->
        hide(socket.assigns.id)

        {:noreply,
         assign(socket,
           changeset: Event.invoice_changeset(%Event{}, %{})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp process_uploads(socket) do
    consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
      {:ok,
       Commissions.make_attachment!(
         socket.assigns.current_user,
         path,
         entry.client_type,
         entry.client_name
       )}
    end)
  end

  def render(assigns) do
    ~F"""
    <invoice-modal id={@id}>
      <Form
        for={@changeset}
        change="change"
        opts={
          id: "#{@id}-form",
          # NOTE: This is a workaround for a Surface bug in >=0.7.1: https://github.com/surface-ui/surface/issues/582
          # TODO: make this a regular submit="add_comment" when the bug gets fixed.
          phx_submit: "submit",
          phx_target: @myself
        }
      >
        <Modal id={@id <> "_inner_modal"}>
          <:title>Invoice Customer</:title>
          <div class="py-4">
            Use this form to submit an invoice. Once submitted, the invoice will appear in the commission timeline and the customer will be able to process the payment through Stripe.
          </div>
          <Field class="field" name={:amount}>
            <InputContext assigns={assigns}>
              <Label class="label py-2">
                <span class="label-text">
                  Invoice Amount
                  <div
                    class="tooltip tooltip-right"
                    data-tip="Total amount to invoice customer for. If you've configured multiple currencies, you may choose which one to invoice with."
                  >
                    <i class="fas fa-info-circle" />
                  </div>
                </span>
              </Label>
            </InputContext>
          </Field>
          <div class="flex flex-row gap-2 items-center py-2">
            {#case @studio.payment_currencies}
              {#match [_]}
                <div class="flex flex-basis-1/4">{"#{to_string(@studio.default_currency)}#{Money.Currency.symbol(@studio.default_currency)}"}</div>
                <HiddenInput name={:currency} value={@studio.default_currency} />
              {#match _}
                <div class="flex-basis-1/4">
                  <Select
                    name={:currency}
                    show_label={false}
                    options={@studio.payment_currencies
                    |> Enum.map(&{"#{to_string(&1)}#{Money.Currency.symbol(&1)}", &1})}
                    selected={@studio.default_currency}
                  />
                </div>
            {/case}
            <div class="grow">
              <TextInput name={:amount} show_label={false} opts={required: true, placeholder: "12.34"} />
            </div>
          </div>
          <MarkdownInput
            id="{@id}-markdown-input"
            name={:text}
            label="Invoice Text"
            info="Brief summary of what this invoice is meant to cover, for the record."
            class="w-full"
            upload={@uploads.attachment}
            cancel_upload="cancel_upload"
          />
          <:action>
            <div class="flex flex-col items-end">
              {#if Enum.empty?(@uploads.attachment.entries)}
                <Submit changeset={@changeset} class="w-full md:w-fit" label="Post" />
              {#else}
                <Checkbox name={:required} label="Require Payment to View Attachment(s)" />
                <Submit changeset={@changeset} class="w-full md:w-fit" label="Post" />
              {/if}
            </div>
          </:action>
        </Modal>
      </Form>
    </invoice-modal>
    """
  end
end
