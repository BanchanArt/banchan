defmodule BanchanWeb.CommissionLive.Components.StatusBox do
  @moduledoc """
  Action box that changes behavior based on the commission's status.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Payments
  alias Banchan.Repo

  alias Surface.Components.Form

  alias BanchanWeb.Components.{
    Button,
    Collapse,
    Modal
  }

  alias BanchanWeb.Components.Form.FancySelect

  prop(current_user, :struct, from_context: :current_user)
  prop(current_user_member?, :boolean, from_context: :current_user_member?)
  prop(commission, :struct, from_context: :commission)

  data(existing_open, :struct)
  data(statuses, :list)
  data(status_state, :map)

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    existing_open = Payments.open_invoice(socket.assigns.commission) |> Repo.preload(:event)

    statuses =
      Commissions.Common.status_values()
      |> Enum.filter(fn status ->
        status == socket.assigns.commission.status ||
          (status not in [:withdrawn, :ready_for_review, :approved] &&
             Commissions.status_transition_allowed?(
               socket.assigns.current_user_member?,
               socket.assigns.current_user.id == socket.assigns.commission.client_id,
               socket.assigns.commission.status,
               status
             ))
      end)

    {:ok,
     socket
     |> assign(
       existing_open: existing_open,
       status_state:
         to_form(%{
           "status" => "#{Enum.find_index(statuses, &(&1 == socket.assigns.commission.status))}"
         }),
       statuses: statuses
     )}
  end

  def handle_event("update_status", %{"status" => status}, socket) do
    {status_idx, ""} = Integer.parse(status)
    status = Enum.at(socket.assigns.statuses, status_idx)

    if status == :rejected && Commissions.commission_active?(socket.assigns.commission) do
      Modal.show(socket.assigns.id <> "-reject-modal")
      {:noreply, socket}
    else
      update_status(status, socket)
    end
  end

  def handle_event("confirm_reject", _, socket) do
    ret = update_status(:rejected, socket)
    Modal.hide(socket.assigns.id <> "-reject-modal")
    ret
  end

  defp update_status(status, socket) do
    case Commissions.update_status(socket.assigns.current_user, socket.assigns.commission, status) do
      {:ok, _} ->
        Collapse.set_open(socket.assigns.id <> "-approval-collapse", false)
        Collapse.set_open(socket.assigns.id <> "-review-confirm-collapse", false)
        {:noreply, socket}

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_navigate(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}
    end
  end

  def render(assigns) do
    has_transitions? = !Enum.empty?(assigns.statuses)

    ~F"""
    <div class="flex flex-col w-full gap-4">
      <h3 class="text-sm font-medium opacity-75">Commission Status</h3>
      {#if has_transitions?}
        <Form for={@status_state} change="update_status">
          <FancySelect
            id={@id <> "-status-selector"}
            class="flex flex-row items-center gap-4 btn btn-primary"
            name={:status}
            show_label={false}
            show_chevron={Enum.count(@statuses) > 1}
            disabled={Enum.count(@statuses) == 1}
            items={@statuses
            |> Enum.map(
              &%{
                label: Commissions.Common.humanize_status(&1),
                value: &1,
                description: Commissions.Common.status_description(&1)
              }
            )}
          />
        </Form>
      {#else}
        <Button disabled label={Commissions.Common.humanize_status(@commission.status)} />
      {/if}
      <div class="text-sm">
        {Commissions.Common.status_description(@commission.status)}
      </div>
      {#if @existing_open}
        <p class="text-sm">There's a <a class="link link-primary" href={"#event-#{@existing_open.event.public_id}"}>pending invoice</a> awaiting payment.</p>
      {/if}

      <Modal id={@id <> "-reject-modal"} class="reject-modal">
        <:title>Confirm Rejection</:title>
        Are you sure you want to reject this commission after accepting it?
        <p class="font-bold text-warning">
          NOTE: Any unreleased deposits will be canceled or refunded.
        </p>
        <:action>
          <Button class="reject-btn" click="confirm_reject">Confirm</Button>
        </:action>
      </Modal>
    </div>
    """
  end
end
