defmodule BanchanWeb.CommissionLive.Components.InvoiceCollapse do
  @moduledoc """
  Modal pop-up for posting invoices.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, Label}

  alias Banchan.Commissions.Event
  alias Banchan.Payments
  alias Banchan.Repo
  alias Banchan.Uploads
  alias Banchan.Utils

  alias BanchanWeb.Components.Collapse

  alias BanchanWeb.Components.Form.{
    Checkbox,
    HiddenInput,
    MarkdownInput,
    Select,
    Submit,
    TextInput
  }

  prop commission, :struct, from_context: :commission
  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?

  data changeset, :struct
  data uploads, :map
  data studio, :struct

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
     |> allow_upload(:attachment,
       accept: :any,
       max_entries: 10,
       max_file_size: Application.fetch_env!(:banchan, :max_attachment_size)
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

    case Payments.invoice(
           socket.assigns.current_user,
           socket.assigns.commission,
           attachments,
           %{event | "amount" => Utils.moneyfy(amount, currency)}
         ) do
      {:ok, _event} ->
        Collapse.set_open(socket.assigns.id <> "-invoice-collapse", false)

        {:noreply,
         assign(socket,
           changeset: Event.invoice_changeset(%Event{}, %{})
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
    consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
      {:ok,
       Uploads.save_file!(socket.assigns.current_user, path, entry.client_type, entry.client_name)}
    end)
  end

  def render(assigns) do
    ~F"""
    <invoice-collapse id={@id}>
      <Form for={@changeset} change="change" submit="submit" opts={id: "#{@id}-form"}>
        <Collapse id={@id <> "-invoice-collapse"} class="w-full mt-2">
          <:header>
            <div class="text-lg font-medium">Send Invoice</div>
          </:header>
          <Field class="field" name={:amount}>
            <Label class="label py-2">
              <span class="label-text">
                Invoice Amount
                <div
                  class="tooltip"
                  data-tip="Total amount to invoice client for. If you've configured multiple currencies, you may choose which one to invoice with."
                >
                  <i class="fas fa-info-circle" />
                </div>
              </span>
            </Label>
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
                    selected={case Ecto.Changeset.fetch_field(@changeset, :amount) do
                      {_, nil} -> @studio.default_currency
                      :error -> @studio.default_currency
                      {_, amount} -> amount.currency
                    end}
                  />
                </div>
            {/case}
            <div class="grow">
              <TextInput name={:amount} show_label={false} opts={required: true, placeholder: "12.34"} />
            </div>
          </div>
          <MarkdownInput
            id={@id <> "-markdown-input"}
            name={:text}
            label="Invoice Text"
            info="Brief summary of what this invoice is meant to cover, for the record."
            class="w-full"
            upload={@uploads.attachment}
            cancel_upload="cancel_upload"
          />
          <div class="flex flex-col items-end">
            {#if Enum.empty?(@uploads.attachment.entries)}
              <Submit changeset={@changeset} class="w-full md:w-fit" label="Post" />
            {#else}
              <Checkbox name={:required} label="Require Payment to View Attachment(s)" />
              <Submit changeset={@changeset} class="w-full md:w-fit" label="Post" />
            {/if}
          </div>
        </Collapse>
      </Form>
    </invoice-collapse>
    """
  end
end
