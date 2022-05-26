defmodule BanchanWeb.CommissionLive.Components.Commission do
  @moduledoc """
  Commission display for commission listing page
  """
  use BanchanWeb, :component

  alias Surface.Components.LivePatch

  alias BanchanWeb.CommissionLive.Components.{
    CommentBox,
    DraftBox,
    StatusBox,
    SummaryEditor,
    Timeline
  }

  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true
  prop subscribed?, :boolean, required: true
  prop uri, :string, required: true
  prop toggle_subscribed, :event, required: true

  def render(assigns) do
    ~F"""
    <div class="md:container md:basis-3/4">
      <h1 class="text-3xl pt-4 px-4">
        <LivePatch class="md:hidden p-2" to={Routes.commission_path(Endpoint, :index)}>
          <i class="fas fa-arrow-left text-2xl" />
        </LivePatch>
        {@commission.title}
      </h1>
      <div class="divider" />
      <div class="p-2">
        <div class="flex flex-col md:grid md:grid-cols-3 gap-4">
          <div class="flex flex-col md:order-2">
            <DraftBox
              id="draft-box"
              current_user={@current_user}
              current_user_member?={@current_user_member?}
              commission={@commission}
            />
            <div class="divider" />
            <button type="button" :on-click={@toggle_subscribed} class="btn btn-primary btn-sm">
              {#if @subscribed?}
                Unsubscribe
              {#else}
                Subscribe
              {/if}
            </button>
            <div class="divider" />
            <SummaryEditor
              id="summary-editor"
              current_user={@current_user}
              current_user_member?={@current_user_member?}
              commission={@commission}
              allow_edits={@current_user_member?}
            />
          </div>
          <div class="divider md:hidden" />
          <div class="flex flex-col md:col-span-2 md:order-1">
            <Timeline
              uri={@uri}
              commission={@commission}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
            />
            <div class="divider" />
            <div class="flex flex-col gap-4">
              <StatusBox
                id="action-box"
                commission={@commission}
                current_user={@current_user}
                current_user_member?={@current_user_member?}
              />
              <CommentBox
                id="comment-box"
                commission={@commission}
                actor={@current_user}
                current_user_member?={@current_user_member?}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
