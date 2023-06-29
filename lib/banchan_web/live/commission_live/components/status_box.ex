defmodule BanchanWeb.CommissionLive.Components.StatusBox do
  @moduledoc """
  Action box that changes behavior based on the commission's status.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Payments

  alias BanchanWeb.Components.{
    # Button,
    Collapse,
    Dropdown
  }

  alias BanchanWeb.CommissionLive.Components.StatusItem

  prop current_user, :struct, from_context: :current_user
  prop current_user_member?, :boolean, from_context: :current_user_member?
  prop commission, :struct, from_context: :commission

  data invoices_paid?, :boolean

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    invoices = Payments.list_invoices(commission: socket.assigns.commission)

    invoices_paid? =
      !Enum.empty?(invoices) &&
        Enum.all?(invoices, &Payments.invoice_finished?(&1)) &&
        Enum.any?(invoices, &Payments.invoice_paid?(&1))

    {:ok, socket |> assign(invoices_paid?: invoices_paid?)}
  end

  def handle_event("update_status", %{"value" => status}, socket) do
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
    ~F"""
    <div class="flex flex-col gap-2 w-full">
      <div class="flex flex-row gap-2 items-center">
        <div class="text-xl font-medium">
          Status:
        </div>
        <Dropdown show_caret? label={Commissions.Common.humanize_status(@commission.status)}>
          <StatusItem
            click="update_status"
            status={:accepted}
            commission={@commission}
            current_user_member?={@current_user_member?}
            current_user={@current_user}
          />
          <StatusItem
            click="update_status"
            status={:rejected}
            commission={@commission}
            current_user_member?={@current_user_member?}
            current_user={@current_user}
          />
          <StatusItem
            click="update_status"
            status={:paused}
            commission={@commission}
            current_user_member?={@current_user_member?}
            current_user={@current_user}
          />
          <StatusItem
            click="update_status"
            status={:in_progress}
            commission={@commission}
            current_user_member?={@current_user_member?}
            current_user={@current_user}
          />
          <StatusItem
            click="update_status"
            status={:waiting}
            commission={@commission}
            current_user_member?={@current_user_member?}
            current_user={@current_user}
          />
        </Dropdown>
        <div
          class="tooltip md:tooltip-left"
          data-tip={Commissions.Common.status_description(@commission.status)}
        >
          <i class="fas fa-info-circle" />
        </div>
      </div>
    </div>
    """
  end
end
