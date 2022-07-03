defmodule BanchanWeb.CommissionLive.Components.StatusBox do
  @moduledoc """
  Action box that changes behavior based on the commission's status.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions

  alias BanchanWeb.CommissionLive.Components.InvoiceModal
  alias BanchanWeb.Components.{Button, Modal}

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true

  def handle_event("update_status", %{"value" => status}, socket) do
    Commissions.update_status(socket.assigns.current_user, socket.assigns.commission, status)
    Modal.hide(socket.assigns.id <> "_approval_modal")
    {:noreply, socket}
  end

  def handle_event("open_approval_modal", _, socket) do
    Modal.show(socket.assigns.id <> "_approval_modal")
    {:noreply, socket}
  end

  def handle_event("open_invoice_modal", _, socket) do
    InvoiceModal.show(socket.assigns.id <> "_invoice_modal")
    {:noreply, socket}
  end

  def render(assigns) do
    ~F"""
    <div class="p-4 flex flex-col gap-2 divide-y-2 divide-neutral-content divide-opacity-10 w-full border border-neutral rounded-box">
      <div class="text-2xl">{Commissions.Common.humanize_status(@commission.status)}</div>
      {#if @current_user.id == @commission.client_id}
        <div class="flex flex-col">
          {#case @commission.status}
            {#match :submitted}
              You have submitted this commission. Please wait while the studio decides whether to accept it.
            {#match :accepted}
              The studio has accepted this commission and has committed to working on it.
            {#match :rejected}
              The studio has rejected this commission.
            {#match :in_progress}
              The studio has begun work on this commission. Keep an eye out for drafts!
            {#match :paused}
              The studio has temporarily paused work on this commission.
            {#match :waiting}
              The studio is waiting for your response before continuing work.
            {#match :ready_for_review}
              This commission is ready for your final review. If you approve it, you agree to release all payments to the studio for payout.
              <Button click="open_approval_modal" label="Approve" />
            {#match :approved}
              This commission has been approved. All deposits will be released to the studio.
            {#match :withdrawn}
              This commission has been withdrawn. You may request a refund of deposited but unreleased funds from the studio, separately.
              <Button click="update_status" value="submitted" label="Submit Again" />
          {/case}
        </div>
      {/if}
      {#if @current_user_member?}
        <div class="flex flex-col">
          {#case @commission.status}
            {#match :submitted}
              This commission has been submitted for acceptance. Accepting it will mark slots as used if you've configured them for this commission. By accepting this commission, this studio commits to working on it soon.
              <div class="flex flex-col md:flex-row">
                <Button class="flex-1" click="update_status" value="accepted" label="Accept" />
                <Button class="open-invoice-modal flex-1" click="open_invoice_modal" label="New Invoice" />
              </div>
            {#match :accepted}
              This studio has accepted this commission but has not begun work on it yet.
              <div class="flex flex-col md:flex-row">
                <Button class="flex-1" click="update_status" value="in_progress" label="Mark as In Progress" />
                <Button
                  class="flex-1"
                  click="update_status"
                  value="ready_for_review"
                  label="Request Final Approval"
                />
                <Button class="fopen-invoice-modal lex-1" click="open_invoice_modal" label="New Invoice" />
              </div>
            {#match :rejected}
              This studio has rejected this commission and will not be working on it.
            {#match :in_progress}
              This commission is actively being worked on.
              <div class="flex flex-col md:flex-row">
                <Button
                  class="flex-1"
                  click="update_status"
                  value="ready_for_review"
                  label="Request Final Approval"
                />
                <Button class="flex-1" click="update_status" value="paused" label="Pause Work" />
                <Button class="flex-1" click="update_status" value="waiting" label="Wait for Customer" />
                <Button class="fopen-invoice-modal lex-1" click="open_invoice_modal" label="New Invoice" />
              </div>
            {#match :paused}
              Ths studio has temporarily paused work on this commission.
              <div class="flex flex-col md:flex-row">
                <Button class="flex-1" click="update_status" value="in_progress" label="Resume" />
                <Button class="fopen-invoice-modal lex-1" click="open_invoice_modal" label="New Invoice" />
              </div>
            {#match :waiting}
              The studio is waiting for your response before continuing work.
              <div class="flex flex-col md:flex-row">
                <Button class="flex-1" click="update_status" value="in_progress" label="Resume" />
                <Button class="fopen-invoice-modal lex-1" click="open_invoice_modal" label="New Invoice" />
              </div>
            {#match :ready_for_review}
              This commission has been marked for final review. The client will determine whether to close it out and pay out any money deposited so far.
              <div class="flex flex-col md:flex-row">
                <Button class="flex-1" click="update_status" value="in_progress" label="Return to In Progress" />
                <Button class="fopen-invoice-modal lex-1" click="open_invoice_modal" label="New Invoice" />
              </div>
            {#match :withdrawn}
              This commission has been withdrawn. It is recommended that you refund any deposits to the client.
              <Button class="flex-1" click="update_status" value="accepted" label="Reopen" />
            {#match :approved}
              This commission has been approved by the client. Any deposits will be released to you for payout once available.
              <Button click="update_status" value="accepted" label="Reopen" />
          {/case}
        </div>
      {/if}

      <Modal id={@id <> "_approval_modal"}>
        <:title>
          Confirm Final Approal
        </:title>
        All deposited funds will be made available immediately to the studio and the commission will be closed. <p class="font-bold text-warning">WARNING: You will not be able to request a refund once approved.</p>
        <:action>
          <Button click="update_status" value="approved" label="Confirm" />
        </:action>
      </Modal>

      {#if @current_user_member?}
        <InvoiceModal
          id={@id <> "_invoice_modal"}
          commission={@commission}
          current_user={@current_user}
          current_user_member?={@current_user_member?}
        />
      {/if}
    </div>
    """
  end
end
