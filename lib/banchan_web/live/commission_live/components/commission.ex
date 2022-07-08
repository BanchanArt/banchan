defmodule BanchanWeb.CommissionLive.Components.Commission do
  @moduledoc """
  Commission display for commission listing page
  """
  use BanchanWeb, :live_component

  alias Surface.Components.{Form, LivePatch}

  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, Notifications}

  alias BanchanWeb.Components.{Button, Collapse}
  alias BanchanWeb.Components.Form.{Submit, TextInput}

  alias BanchanWeb.CommissionLive.Components.{
    BalanceBox,
    CommentBox,
    InvoiceCollapse,
    StatusBox,
    StudioBox,
    SummaryEditor,
    Timeline,
    UploadsBox
  }

  prop users, :map, required: true
  prop current_user, :struct, required: true
  prop current_user_member?, :boolean, required: true
  prop commission, :struct, required: true
  prop uri, :string, required: true

  prop subscribed?, :boolean
  prop archived?, :boolean

  data deposited, :struct
  data title_changeset, :struct, default: nil

  def events_updated(id) do
    send_update(__MODULE__, id: id, events_updated: true)
  end

  def update(%{events_updated: true}, socket) do
    UploadsBox.reload(socket.assigns.id <> "-uploads-box")
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    socket =
      socket
      |> assign(
        archived?: Commissions.archived?(socket.assigns.current_user, socket.assigns.commission),
        subscribed?:
          Notifications.user_subscribed?(socket.assigns.current_user, socket.assigns.commission),
        deposited:
          Commissions.deposited_amount(
            socket.assigns.current_user,
            socket.assigns.commission,
            socket.assigns.current_user_member?
          )
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("withdraw", _, socket) do
    {:ok, _} =
      Commissions.update_status(
        socket.assigns.current_user,
        socket.assigns.commission,
        "withdrawn"
      )

    Collapse.set_open(socket.assigns.id <> "-withdraw-confirmation", false)
    {:noreply, socket}
  end

  def handle_event("toggle_subscribed", _, socket) do
    if socket.assigns.subscribed? do
      Notifications.unsubscribe_user!(socket.assigns.current_user, socket.assigns.commission)
    else
      Notifications.subscribe_user!(socket.assigns.current_user, socket.assigns.commission)
    end

    {:noreply, assign(socket, subscribed?: !socket.assigns.subscribed?)}
  end

  def handle_event("toggle_archived", _, socket) do
    {:ok, _} =
      Commissions.update_archived(
        socket.assigns.current_user,
        socket.assigns.commission,
        !socket.assigns.archived?
      )

    {:noreply, assign(socket, archived?: !socket.assigns.archived?)}
  end

  def handle_event("edit_title", _, socket) do
    {:noreply,
     socket
     |> assign(title_changeset: Commission.update_title_changeset(socket.assigns.commission))}
  end

  def handle_event("cancel_edit_title", _, socket) do
    {:noreply, socket |> assign(title_changeset: nil)}
  end

  def handle_event("change_title", val, socket) do
    changeset =
      %Commission{}
      |> Commission.update_title_changeset(val["commission"])

    {:noreply, socket |> assign(title_changeset: changeset)}
  end

  def handle_event("submit_title", val, socket) do
    Commissions.update_title(
      socket.assigns.current_user,
      socket.assigns.commission,
      val["commission"]
    )
    |> case do
      {:ok, _} ->
        # Commission will be updated through broadcast
        {:noreply, socket |> assign(title_changeset: nil)}

      {:error, %Ecto.Changeset{} = err} ->
        {:noreply, socket |> assign(title_changeset: err)}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="relative">
      <h1 class="text-3xl flex flex-row items-center pt-4 px-4 sticky top-16 bg-base-100 z-30 pb-2 border-b-2 border-base-content border-opacity-10 opacity-100">
        <LivePatch class="px-2 py-4" to={Routes.commission_path(Endpoint, :index)}>
          <i class="fas fa-arrow-left text-2xl" />
        </LivePatch>
        {#if @title_changeset}
          <Form for={@title_changeset} class="w-full" change="change_title" submit="submit_title">
            <div class="flex flex-row w-full items-center">
              <div class="grow">
                <TextInput class="w-full text-3xl" show_label={false} name={:title} />
              </div>
              <Submit changeset={@title_changeset} label="Save" />
              <Button class="btn-error" label="Cancel" click="cancel_edit_title" />
            </div>
          </Form>
        {#else}
          <div class="px-2 flex flex-row w-full items-center">
            <div class="grow w-full flex flex-row items-center gap-2">
              {@commission.title}
              {#if @archived?}
                <div class="badge badge-warning badge-lg cursor-default">Archived</div>
              {/if}
            </div>
            <Button label="Edit Title" class="hidden md:flex btn-sm btn-link" click="edit_title" />
          </div>
        {/if}
      </h1>
      <div class="p-4">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div class="flex flex-col md:order-2">
            <StudioBox commission={@commission} class="rounded-box hover:bg-base-200 p-2 transition-all" />
            <div class="divider" />
            <StatusBox
              id="status-box"
              commission={@commission}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
            />
            <div class="divider" />
            <div class="text-lg font-medium">Summary</div>
            <BalanceBox
              default_currency={@commission.studio.default_currency}
              deposited={@deposited}
              line_items={@commission.line_items}
            />
            <Collapse id="summary-details" class="px-2">
              <:header><div class="font-medium">Details:</div></:header>
              <SummaryEditor
                id="summary-editor"
                current_user={@current_user}
                current_user_member?={@current_user_member?}
                commission={@commission}
                allow_edits={@current_user_member?}
              />
            </Collapse>
            {#if @current_user_member?}
              <div class="divider" />
              <InvoiceCollapse
                id={@id <> "-invoice-collapse"}
                commission={@commission}
                current_user={@current_user}
                current_user_member?={@current_user_member?}
              />
            {/if}
            <div class="divider" />
            <UploadsBox
              id={@id <> "-uploads-box"}
              current_user={@current_user}
              current_user_member?={@current_user_member?}
              commission={@commission}
            />
            {bottom_buttons(assigns, true)}
          </div>
          <div class="divider md:hidden" />
          <div class="flex flex-col md:col-span-2 md:order-1">
            <Timeline
              uri={@uri}
              users={@users}
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
            {bottom_buttons(assigns, false)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  def bottom_buttons(assigns, desktop?) do
    ~F"""
    <div class={"md:hidden": !desktop?, "hidden md:block": desktop?}>
      <div class={"divider md:hidden": !desktop?, "hidden md:divider md:flex": desktop?} />
      <div class="w-full">
        <div class="text-sm font-medium pb-2">Notifications</div>
        <button
          type="button"
          :on-click="toggle_subscribed"
          class="btn btn-sm w-full"
          phx-target={@myself}
        >
          {#if @subscribed?}
            Unsubscribe
          {#else}
            Subscribe
          {/if}
        </button>
      </div>
      <div class="divider" />
      <button
        type="button"
        :on-click="toggle_archived"
        class="btn btn-sm my-2 w-full"
        phx-target={@myself}
      >
        {#if @archived?}
          Unarchive
        {#else}
          Archive
        {/if}
      </button>
      {#if @current_user.id == @commission.client_id && @commission.status != :withdrawn}
        <Collapse
          id={@id <> "-withdraw-confirmation" <> if desktop?, do: "-desktop", else: "-mobile"}
          show_arrow={false}
          class="w-full my-2 bg-base-200"
        >
          <:header>
            <button type="button" class="btn btn-sm w-full">
              Withdraw
            </button>
          </:header>
          <p>
            Your commission will be withdrawn and you won't be able to re-open it unless the studio does it for you.
          </p>
          <p class="py-2">Are you sure?</p>
          <button
            disabled={@commission.status == :withdrawn || @current_user.id != @commission.client_id}
            type="button"
            :on-click="withdraw"
            class="btn btn-sm btn-error my-2 w-full"
          >
            Confirm
          </button>
        </Collapse>
      {/if}
    </div>
    """
  end
end
