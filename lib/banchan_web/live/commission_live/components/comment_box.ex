defmodule BanchanWeb.CommissionLive.Components.CommentBox do
  @moduledoc """
  Message/Chat box for the Commission page.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Commissions.Event
  alias Banchan.Repo
  alias Banchan.Utils

  alias Surface.Components.Form

  alias BanchanWeb.Components.Form.{
    Checkbox,
    HiddenInput,
    MarkdownInput,
    Select,
    Submit,
    TextInput
  }

  prop commission, :struct, required: true
  prop actor, :struct, required: true
  prop current_user_member?, :boolean, required: true

  data changeset, :struct
  data uploads, :map
  data studio, :struct

  def update(assigns, socket) do
    studio =
      if socket.assigns[:studio] && socket.assigns[:studio].id == assigns[:commission].studio_id do
        socket.assigns.studio
      else
        (assigns[:commission] |> Repo.preload(:studio)).studio
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(studio: studio)
     |> assign(changeset: Event.comment_changeset(%Event{}, %{}))
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
      |> Event.comment_changeset(%{event | "amount" => Utils.moneyfy(amount, currency)})
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachment, ref)}
  end

  def handle_event(
        "add_comment",
        %{"event" => %{"amount" => amount, "currency" => currency} = event},
        socket
      )
      when amount != "" do
    attachments = process_uploads(socket)

    case Commissions.invoice(
           socket.assigns.actor,
           socket.assigns.commission,
           socket.assigns.current_user_member?,
           attachments,
           %{event | "amount" => Utils.moneyfy(amount, currency)}
         ) do
      {:ok, _event} ->
        {:noreply,
         assign(socket,
           changeset: Event.comment_changeset(%Event{}, %{})
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_event("add_comment", %{"event" => %{"text" => text}}, socket) do
    attachments = process_uploads(socket)

    case Commissions.add_comment(
           socket.assigns.actor,
           socket.assigns.commission,
           socket.assigns.current_user_member?,
           attachments,
           text
         ) do
      {:ok, _event} ->
        {:noreply,
         assign(socket,
           changeset:
             Commissions.change_event(
               %Event{
                 type: :comment
               },
               %{}
             )
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp process_uploads(socket) do
    consume_uploaded_entries(socket, :attachment, fn %{path: path}, entry ->
      {:ok,
       Commissions.make_attachment!(
         socket.assigns.actor,
         path,
         entry.client_type,
         entry.client_name
       )}
    end)
  end

  def render(assigns) do
    ~F"""
    <div id={@id} class="message-box">
      <Form
        for={@changeset}
        change="change"
        opts={
          id: "#{@id}-form",
          # NOTE: This is a workaround for a Surface bug in >=0.7.1: https://github.com/surface-ui/surface/issues/582
          # TODO: make this a regular submit="add_comment" when the bug gets fixed.
          phx_submit: "add_comment",
          phx_target: @myself
        }
      >
        <div class="block space-y-4">
          <MarkdownInput
            id="{@id}-markdown-input"
            name={:text}
            show_label={false}
            class="w-full"
            upload={@uploads.attachment}
            cancel_upload="cancel_upload"
          />
          {#if @current_user_member?}
            <div class="flex flex-row gap-2 items-center">
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
                <TextInput name={:amount} show_label={false} opts={placeholder: "Invoice Amount (optional)"} />
              </div>
            </div>
            <div class="flex flex-row-reverse">
              {#if Enum.empty?(@uploads.attachment.entries)}
                <Submit changeset={@changeset} class="w-full md:w-fit ml-auto" label="Post" />
              {#else}
                <Checkbox name={:required} label="Require Payment to View Draft" />
                <Submit changeset={@changeset} class="w-full md:w-fit ml-auto" label="Submit Draft" />
              {/if}
            </div>
          {#else}
            <div class="flex flex-row-reverse">
              <Submit changeset={@changeset} class="w-full md:w-fit ml-auto" label="Post" />
            </div>
          {/if}
        </div>
      </Form>
    </div>
    """
  end
end
