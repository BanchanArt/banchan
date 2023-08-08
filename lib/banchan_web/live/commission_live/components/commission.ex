defmodule BanchanWeb.CommissionLive.Components.Commission do
  @moduledoc """
  Commission display for commission listing page
  """
  use BanchanWeb, :live_component

  alias Surface.Components.{Form, LivePatch}

  alias Banchan.Commissions
  alias Banchan.Commissions.{Commission, Notifications}
  alias Banchan.Payments

  alias BanchanWeb.Components.{Button, Collapse, Icon, Markdown, ReportModal}
  alias BanchanWeb.Components.Form.{Submit, TextInput}

  alias BanchanWeb.CommissionLive.Components.{
    CommentBox,
    OfferingBox,
    StatusBox,
    SummaryBox,
    Timeline,
    UploadsBox
  }

  prop studio, :struct, from_context: :studio
  prop(users, :map, required: true)
  prop(current_user, :struct, from_context: :current_user)
  prop(current_user_member?, :boolean, from_context: :current_user_member?)
  prop(commission, :struct, required: true)

  prop(subscribed?, :boolean)
  prop(archived?, :boolean)

  data(title_changeset, :struct, default: nil)

  def events_updated(id) do
    send_update(__MODULE__, id: id, events_updated: true)
  end

  def update(%{events_updated: true}, socket) do
    UploadsBox.reload(socket.assigns.id <> "-uploads-box")

    {:ok,
     socket
     |> Context.put(
       released_amount: Payments.released_amount(socket.assigns.commission),
       escrowed_amount: Payments.escrowed_amount(socket.assigns.commission)
     )}
  end

  def update(assigns, socket) do
    socket = socket |> assign(assigns)

    socket =
      socket
      |> assign(
        archived?: Commissions.archived?(socket.assigns.current_user, socket.assigns.commission),
        subscribed?:
          Notifications.user_subscribed?(socket.assigns.current_user, socket.assigns.commission)
      )
      |> Context.put(
        released_amount: Payments.released_amount(socket.assigns.commission),
        escrowed_amount: Payments.escrowed_amount(socket.assigns.commission)
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("withdraw", _, socket) do
    case Commissions.update_status(
           socket.assigns.current_user,
           socket.assigns.commission,
           "withdrawn"
         ) do
      {:ok, _} ->
        Collapse.set_open(socket.assigns.id <> "-withdraw-confirmation", false)
        {:noreply, socket}

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_navigate(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to access that commission.")
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}

      {:error, :disabled} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "You are not authorized to access that commission because your account has been disabled."
         )
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}
    end
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

      {:error, :blocked} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are blocked from further interaction with this studio.")
         |> push_navigate(
           to: Routes.commission_path(Endpoint, :show, socket.assigns.commission.public_id)
         )}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to access that commission.")
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}

      {:error, :disabled} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "You are not authorized to access that commission because your account has been disabled."
         )
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}
    end
  end

  def render(assigns) do
    ~F"""
    <div class="relative">
      <h1 class="sticky z-30 flex flex-row items-center px-4 pb-2 text-3xl border-b-2 opacity-100 top-16 bg-base-100 border-base-content border-opacity-10">
        <LivePatch
          class="px-2 pb-4"
          to={if is_nil(@studio) do
            ~p"/commissions"
          else
            ~p"/studios/#{@studio.handle}/commissions"
          end}
        >
          <Icon name="arrow-left" size="4" />
        </LivePatch>
        {#if @title_changeset}
          <Form for={@title_changeset} class="w-full" change="change_title" submit="submit_title">
            <div class="flex flex-row items-center w-full">
              <div class="grow">
                <TextInput class="w-full text-3xl" show_label={false} name={:title} />
              </div>
              <Submit changeset={@title_changeset} label="Save" />
              <Button class="btn-error" label="Cancel" click="cancel_edit_title" />
            </div>
          </Form>
        {#else}
          <div class="flex flex-row items-center w-full px-2 pb-2">
            <div class="flex flex-row items-center w-full gap-2 grow">
              {@commission.title}
              {#if @archived?}
                <div class="cursor-default badge badge-warning badge-lg">Archived</div>
              {/if}
            </div>
            <Button label="Edit Title" class="hidden md:flex btn-sm btn-link" click="edit_title" />
          </div>
        {/if}
      </h1>
      <div class="p-4">
        <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div class="flex flex-col md:order-2">
            <SummaryBox id={@id <> "-summary-box"} />
            <div class="divider" />
            <StatusBox id={@id <> "-status-box"} />
            <div class="divider" />
            <UploadsBox id={@id <> "-uploads-box"} />
            <div class="divider" />
            <OfferingBox
              offering={@commission.offering}
              class="transition-all rounded-box hover:bg-base-200"
            />
            {bottom_buttons(assigns, true)}
          </div>
          <div class="divider md:hidden" />
          <div class="flex flex-col md:col-span-2 md:order-1">
            <Timeline users={@users} report_modal_id={@id <> "-report-modal"} />
            <div class="divider" />
            <div class="flex flex-col gap-4">
              <CommentBox id={@id <> "-comment-box"} />
            </div>
            {bottom_buttons(assigns, false)}
            {#if @commission.terms}
              <div class="divider" />
              <div class="p-4 rounded-lg shadow-lg bg-base-200">
                <Collapse id="terms-collapse">
                  <:header>Commission Terms</:header>
                  <Markdown content={@commission.terms} />
                </Collapse>
              </div>
            {/if}
          </div>
        </div>
      </div>
      <ReportModal id={@id <> "-report-modal"} current_user={@current_user} />
    </div>
    """
  end

  def bottom_buttons(assigns, desktop?) do
    ~F"""
    <div class={"md:hidden": !desktop?, "hidden md:block": desktop?}>
      <div class={"divider md:hidden": !desktop?, "hidden md:divider md:flex": desktop?} />
      <div class="w-full">
        <div class="pb-2 text-sm font-medium">Notifications</div>
        <button
          type="button"
          :on-click="toggle_subscribed"
          class="w-full btn btn-sm"
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
        class="w-full my-2 btn btn-sm"
        phx-target={@myself}
      >
        {#if @archived?}
          Unarchive
        {#else}
          Archive
        {/if}
      </button>
      {#if Commissions.status_transition_allowed?(
          @current_user_member?,
          @current_user.id == @commission.client_id || :admin in @current_user.roles ||
            :mod in @current_user.roles,
          @commission.status,
          :withdrawn
        )}
        <Collapse
          id={@id <> "-withdraw-confirmation" <> if desktop?, do: "-desktop", else: "-mobile"}
          show_arrow={false}
          class="w-full my-2 rounded-lg bg-base-200"
        >
          <:header>
            <button type="button" class="w-full btn btn-sm">
              Withdraw
            </button>
          </:header>
          <p>
            Your commission will be withdrawn and you won't be able to re-open it unless the studio does it for you.
          </p>
          <p class="py-2">Are you sure?</p>
          <button
            disabled={@commission.status == :withdrawn}
            type="button"
            :on-click="withdraw"
            phx-target={@myself}
            class="w-full my-2 btn btn-sm btn-error"
          >
            Confirm
          </button>
        </Collapse>
      {/if}
    </div>
    """
  end
end
