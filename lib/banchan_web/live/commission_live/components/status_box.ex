defmodule BanchanWeb.CommissionLive.Components.StatusBox do
  @moduledoc """
  Action box that changes behavior based on the commission's status.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions
  alias Banchan.Payments

  alias BanchanWeb.Components.{Button, Collapse}

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
         |> push_redirect(
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
        <div class="badge badge-primary badge-lg flex flex-row gap-2 items-center cursor-default">
          {Commissions.Common.humanize_status(@commission.status)}
          {#if @current_user.id == @commission.client_id}
            <div class="tooltip md:tooltip-left" data-tip={tooltip_message(@commission.status, false)}>
              <i class="fas fa-info-circle" />
            </div>
          {/if}
          {#if @current_user_member?}
            <div class="tooltip md:tooltip-left" data-tip={tooltip_message(@commission.status, true)}>
              <i class="fas fa-info-circle" />
            </div>
          {/if}
        </div>
      </div>
      {#if @current_user.id == @commission.client_id || :admin in @current_user.roles ||
          :mod in @current_user.roles}
        <div class="flex flex-col">
          {#case @commission.status}
            {#match :ready_for_review}
              {approve(assigns)}
            {#match :withdrawn}
              <Button class="btn-sm w-full" click="update_status" value="submitted" label="Submit Again" />
            {#match _}
          {/case}
        </div>
      {/if}
      {#if @current_user_member? || :admin in @current_user.roles || :mod in @current_user.roles}
        <div class="flex flex-col">
          {#case @commission.status}
            {#match :submitted}
              <Button class="btn-sm w-full" click="update_status" value="accepted" label="Accept" />
            {#match :accepted}
              <Button
                class="btn-sm w-full"
                click="update_status"
                value="in_progress"
                label="Mark as In Progress"
              />
              <Button class="btn-sm w-full" click="update_status" value="paused" label="Pause Work" />
              {ready_for_review(assigns)}
            {#match :rejected}
              <Button class="btn-sm w-full" click="update_status" value="accepted" label="Reopen" />
            {#match :in_progress}
              <Button class="btn-sm w-full" click="update_status" value="paused" label="Pause Work" />
              <Button class="btn-sm w-full" click="update_status" value="waiting" label="Wait for Client" />
              {ready_for_review(assigns)}
            {#match :paused}
              <Button class="btn-sm w-full" click="update_status" value="waiting" label="Wait for Client" />
              <Button class="btn-sm w-full" click="update_status" value="in_progress" label="Resume" />
            {#match :waiting}
              <Button class="btn-sm w-full" click="update_status" value="in_progress" label="Resume" />
              <Button class="btn-sm w-full" click="update_status" value="paused" label="Pause Work" />
              {ready_for_review(assigns)}
            {#match :ready_for_review}
              <Button
                class="btn-sm w-full"
                click="update_status"
                value="in_progress"
                label="Return to In Progress"
              />
            {#match :withdrawn}
              <Button class="btn-sm w-full" click="update_status" value="accepted" label="Reopen" />
            {#match :approved}
              <Button class="btn-sm w-full" click="update_status" value="accepted" label="Reopen" />
          {/case}
        </div>
      {/if}
    </div>
    """
  end

  defp approve(assigns) do
    ~F"""
    <Collapse id={@id <> "-approval-collapse"} show_arrow={false}>
      <:header>
        <Button class="btn-sm w-full" label="Approve" />
      </:header>
      <p>
        All deposited funds will be made available immediately to the studio and the commission will be closed.
      </p>
      <p class="font-bold text-warning">WARNING: This is final and you will not be able to request a refund once approved.</p>
      <Button
        class="btn-sm w-full"
        click="update_status"
        value="approved"
        label="Confirm"
        opts={phx_target: @myself}
      />
    </Collapse>
    """
  end

  defp ready_for_review(assigns) do
    ~F"""
    {#if @invoices_paid?}
      <Button
        class="btn-sm w-full"
        click="update_status"
        value="ready_for_review"
        label="Request Final Approval"
        opts={phx_target: @myself}
      />
    {#else}
      <Collapse id={@id <> "-review-confirm-collapse"} show_arrow={false}>
        <:header>
          <Button class="btn-sm w-full" label="Request Final Approval" />
        </:header>
        <p>You're requesting final approval for a commission before any/all invoices have been completed.</p>
        <p>It's recommended you invoice your client before they are able to approve a commission.</p>
        <p>Are you sure you want to proceed?</p>
        <Button
          class="btn-sm w-full"
          click="update_status"
          value="ready_for_review"
          label="Confirm"
          opts={phx_target: @myself}
        />
      </Collapse>
    {/if}
    """
  end

  defp tooltip_message(status, current_user_member?)

  defp tooltip_message(:submitted, false) do
    "You have submitted this commission. Please wait while the studio decides whether to accept it."
  end

  defp tooltip_message(:accepted, false) do
    "The studio has accepted this commission and has committed to working on it."
  end

  defp tooltip_message(:rejected, false) do
    "The studio has rejected this commission. You may submit a separate one if appropriate."
  end

  defp tooltip_message(:in_progress, false) do
    "The studio has begun work on this commission. Keep an eye out for drafts!"
  end

  defp tooltip_message(:paused, false) do
    "The studio has temporarily paused work on this commission."
  end

  defp tooltip_message(:waiting, false) do
    "The studio is waiting for your response before continuing work."
  end

  defp tooltip_message(:ready_for_review, false) do
    "This commission is ready for your final review. If you approve it, you agree to release all payments to the studio for payout."
  end

  defp tooltip_message(:approved, false) do
    "This commission has been approved. All deposits will be released to the studio."
  end

  defp tooltip_message(:withdrawn, false) do
    "This commission has been withdrawn. You may request a refund of deposited but unreleased funds from the studio, separately."
  end

  defp tooltip_message(:submitted, true) do
    "This commission has been submitted for acceptance. Accepting it will mark slots as used if you've configured them for this commission. By accepting this commission, this studio commits to working on it soon."
  end

  defp tooltip_message(:accepted, true) do
    "This studio has accepted this commission but has not begun work on it yet."
  end

  defp tooltip_message(:rejected, true) do
    "This studio has rejected this commission and will not be working on it."
  end

  defp tooltip_message(:in_progress, true) do
    "This commission is actively being worked on."
  end

  defp tooltip_message(:paused, true) do
    "Ths studio has temporarily paused work on this commission."
  end

  defp tooltip_message(:waiting, true) do
    "The studio is waiting for a client response before continuing work."
  end

  defp tooltip_message(:ready_for_review, true) do
    "This commission has been marked for final review. The client will determine whether to close it out and pay out any money deposited so far."
  end

  defp tooltip_message(:withdrawn, true) do
    "This commission has been withdrawn. It is recommended that you refund any deposits to the client."
  end

  defp tooltip_message(:approved, true) do
    "This commission has been approved by the client. Any deposits will be released to you for payout once available."
  end
end
