defmodule BanchanWeb.CommissionLive.Components.Commission do
  @moduledoc """
  Commission display for commission listing page
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  alias BanchanWeb.CommissionLive.Components.{
    CommentBox,
    DraftBox,
    InvoiceModal,
    StatusBox,
    StudioBox,
    SummaryEditor,
    Timeline
  }

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true
  prop subscribed?, :boolean, required: true
  prop archived?, :boolean, required: true
  prop uri, :string, required: true
  prop toggle_subscribed, :event, required: true
  prop toggle_archived, :event, required: true
  prop withdraw, :event, required: true
  prop invoice_modal_id, :string, required: true
  prop open_invoice_modal, :event, required: true

  def render(assigns) do
    ~F"""
    <div class="relative">
      <h1 class="text-3xl pt-4 px-4 sticky top-16 bg-base-100 z-30 pb-2 border-b-2 border-base-content border-opacity-10 opacity-100">
        <LivePatch class="px-2 py-4" to={Routes.commission_path(Endpoint, :index)}>
          <i class="fas fa-arrow-left text-2xl" />
        </LivePatch>
        {@commission.title}
        {#if @archived?}
          <div class="badge badge-warning badge-lg">Archived</div>
        {/if}
      </h1>
      <div class="p-4">
        <div class="flex flex-col grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="flex flex-col md:col-span-2">
            <StudioBox
              studio={@commission.studio}
              class="md:hidden rounded-box hover:bg-base-200 p-2 transition-all"
            />
            <div class="divider md:hidden" />
            <Timeline
              uri={@uri}
              commission={@commission}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
            />
            <div class="divider" />
            <div class="flex flex-col gap-4">
              <CommentBox
                id="comment-box"
                commission={@commission}
                current_user={@current_user}
                current_user_member?={@current_user_member?}
              />
            </div>
          </div>
          <div class="divider md:hidden" />
          <div class="flex flex-col">
            <StudioBox
              studio={@commission.studio}
              class="hidden md:block rounded-box hover:bg-base-200 p-2 transition-all"
            />
            <div class="divider" />
            <StatusBox
              id="action-box"
              commission={@commission}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
            />
            <div class="divider" />
            <SummaryEditor
              id="summary-editor"
              current_user={@current_user}
              current_user_member?={@current_user_member?}
              commission={@commission}
              allow_edits={@current_user_member?}
            />
            <button
              type="button"
              :if={@current_user_member?}
              :on-click={@open_invoice_modal}
              class="btn btn-primary my-2 w-full open-invoice-modal"
            >
              Send Invoice
            </button>
            <div class="divider" />
            <DraftBox
              id="draft-box"
              current_user={@current_user}
              current_user_member?={@current_user_member?}
              commission={@commission}
            />
            <div class="divider" />
            <button type="button" :on-click={@toggle_subscribed} class="btn btn-sm">
              {#if @subscribed?}
                Unsubscribe
              {#else}
                Subscribe
              {/if}
            </button>
            <div class="divider" />
            <button type="button" :on-click={@toggle_archived} class="btn btn-sm my-2 w-full">
              {#if @archived?}
                Unarchive
              {#else}
                Archive
              {/if}
            </button>
            <button
              disabled={@commission.status == :withdrawn || @current_user.id != @commission.client_id}
              type="button"
              :on-click={@withdraw}
              class="btn btn-sm my-2 w-full"
            >
              Withdraw
            </button>
          </div>
        </div>
      </div>
      {#if @current_user_member?}
        <InvoiceModal
          id={@invoice_modal_id}
          commission={@commission}
          current_user={@current_user}
          current_user_member?={@current_user_member?}
        />
      {/if}
    </div>
    """
  end
end
