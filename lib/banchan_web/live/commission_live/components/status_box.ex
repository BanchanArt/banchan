defmodule BanchanWeb.CommissionLive.Components.StatusBox do
  @moduledoc """
  Action box that changes behavior based on the commission's status.
  """
  use BanchanWeb, :live_component

  alias Banchan.Commissions

  alias BanchanWeb.Components.Button

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true

  def handle_event("update_status", %{"value" => status}, socket) do
    Commissions.update_status(socket.assigns.current_user, socket.assigns.commission, status)
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
            {#match :in_progress}
              The studio has begun work on this commission. Keep an eye out for drafts!
            {#match :paused}
              The studio has temporarily paused work on this commission.
            {#match :waiting}
              The studio is waiting for your response before continuing work.
            {#match :ready_for_review}
              This commission is ready for your final review. If you approve it, you agree to release all payments to the studio for payout.
              <Button click="update_status" value="approved" label="Approve" />
            {#match :approved}
              This commission has been approved. Funds will be paid out to the studio.
            {#match :withdrawn}
              This commission has been withdrawn. Any funds you've deposited will be reimbursed.
          {/case}
        </div>
      {/if}
      {#if @current_user_member?}
        <div class="flex flex-col">
          {#case @commission.status}
            {#match :submitted}
              This commission has been submitted for acceptance. Accepting it will mark slots as used if you've configured them for this commission. By accepting this commission, this studio commits to working on it soon.
              <Button click="update_status" value="accepted" label="Accept" />
            {#match :accepted}
              This studio has accepted this commission but has not begun work on it yet.
              <Button click="update_status" value="in_progress" label="Mark as In Progress" />
            {#match :in_progress}
              This commission is actively being worked on.
              <div class="flex flex-col md:flex-row">
                <Button class="flex-1" click="update_status" value="ready_for_review" label="Ready for Review" />
                <Button class="flex-1" click="update_status" value="paused" label="Pause Work" />
                <Button class="flex-1" click="update_status" value="waiting" label="Wait for Customer" />
              </div>
            {#match :paused}
              Ths studio has temporarily paused work on this commission.
              <Button click="update_status" value="in_progress" label="Resume" />
            {#match :waiting}
              The studio is waiting for your response before continuing work.
              <Button click="update_status" value="in_progress" label="Resume" />
            {#match :ready_for_review}
              This commission has been marked for final review. The client will determine whether to close it out and pay out any money deposited so far.
              <Button click="update_status" value="in_progress" label="Return to In Progress" />
            {#match :withdrawn}
              This commission has been withdrawn. The client will be reimbursed for their deposit.
            {#match :approved}
              This commission has been approved by the client. Funds will be paid out to the studio.
          {/case}
        </div>
      {/if}
    </div>
    """
  end
end
