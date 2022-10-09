defmodule BanchanWeb.StudioLive.Shop do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Banchan.Offerings
  alias Banchan.Studios

  alias Surface.Components.{Link, LiveRedirect}

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.{Button, Card, InfiniteScroll, Markdown}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.{OfferingCard, StudioLayout}

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)
    studio = socket.assigns.studio

    Studios.subscribe_to_stripe_state(studio)

    stripe_onboarding_url =
      if !Studios.charges_enabled?(studio) && socket.assigns.current_user_member? do
        Routes.stripe_account_path(Endpoint, :account_link, studio.handle)
      else
        nil
      end

    {:ok,
     assign(socket,
       offerings: list_offerings(socket),
       stripe_onboarding_url: stripe_onboarding_url
     )}
  end

  @impl true
  def handle_info(%{event: "charges_state_changed", payload: enabled?}, socket) do
    {:noreply,
     socket
     |> assign(studio: %{socket.assigns.studio | stripe_charges_enabled: enabled?})}
  end

  @impl true
  def handle_info(%{event: "details_submitted_changed", payload: submitted?}, socket) do
    {:noreply,
     socket
     |> assign(studio: %{socket.assigns.studio | stripe_details_submitted: submitted?})}
  end

  def handle_event("load_more", _, socket) do
    if socket.assigns.offerings.total_entries >
         socket.assigns.offerings.page_number * socket.assigns.offerings.page_size do
      {:noreply, fetch(socket.assigns.offerings.page_number + 1, socket)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("recheck_stripe", _, socket) do
    # No need to refresh the studio here. It'll get reloaded by the PubSub event(s)
    Studios.charges_enabled?(socket.assigns.studio, true)
    {:noreply, socket}
  end

  @impl true
  def handle_event("archive_studio", _, socket) do
    case Studios.archive_studio(socket.assigns.current_user, socket.assigns.studio) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio archived.")
         |> push_redirect(to: Routes.home_path(Endpoint, :index))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Studio could not be unarchived due to an internal error. Try again later or report this to support@banchan.art"
         )
         |> push_redirect(
           to: Routes.studio_settings_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  @impl true
  def handle_event("unarchive_studio", _, socket) do
    case Studios.unarchive_studio(socket.assigns.current_user, socket.assigns.studio) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio unarchived.")
         |> push_redirect(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Studio could not be unarchived due to an internal error. Try again later or report this to support@banchan.art"
         )
         |> push_redirect(
           to: Routes.studio_settings_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  @impl true
  def handle_event("drop_card", %{"type" => type, "new_index" => new_index}, socket) do
    {:ok, _} =
      Offerings.move_offering(
        socket.assigns.current_user,
        Enum.find(socket.assigns.offerings, &(&1.type == type)),
        new_index
      )

    offerings = list_offerings(socket)

    {:noreply, socket |> assign(offerings: offerings)}
  end

  defp list_offerings(socket, page \\ 1) do
    Offerings.list_offerings(
      studio: socket.assigns.studio,
      include_archived?: socket.assigns.current_user_member?,
      current_user: socket.assigns.current_user,
      order_by: :index,
      include_closed?: true,
      page_size: 16,
      page: page
    )
  end

  defp fetch(page, %{assigns: %{offerings: offerings}} = socket) do
    socket
    |> assign(
      :offerings,
      %{
        offerings
        | page_number: page,
          entries: offerings.entries ++ list_offerings(socket, page).entries
      }
    )
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout flash={@flash} id="studio-layout" studio={@studio} tab={:shop}>
      {#if Studios.charges_enabled?(@studio) && is_nil(@studio.disable_info) && is_nil(@studio.deleted_at) &&
          is_nil(@studio.archived_at)}
        <div
          id="offering-cards"
          :hook="DragDropCards"
          class="sm:px-2 grid grid-cols-2 sm:gap-2 sm:grid-cols-3 auto-rows-fr pt-4"
        >
          <div class="hidden md:flex">
            <Card>
              <:header>
                <h3 class="text-lg font-semibold">
                  About
                </h3>
              </:header>
              <Markdown class="truncate grow max-h-52 whitespace-normal" content={@studio.about} />
              <LiveRedirect
                class="btn btn-link btn-primary"
                to={Routes.studio_about_path(Endpoint, :show, @studio.handle)}
              >
                Read More
              </LiveRedirect>
            </Card>
          </div>
          {#for offering <- @offerings.entries}
            <div
              class={
                "offering-card",
                "cursor-move select-none": @current_user_member? && is_nil(offering.archived_at),
                archived: !is_nil(offering.archived_at)
              }
              draggable={if @current_user_member? && is_nil(offering.archived_at) do
                "true"
              else
                nil
              end}
              data-type={offering.type}
            >
              <OfferingCard
                id={"offering-" <> offering.type}
                current_user={@current_user}
                current_user_member?={@current_user_member?}
                offering={offering}
              />
            </div>
          {#else}
            <div :if={!@current_user_member?} class="p-2">
              This shop has no offerings currently available. Check back in later!
            </div>
          {/for}
          {#if @current_user_member?}
            <LiveRedirect to={Routes.studio_offerings_new_path(Endpoint, :new, @studio.handle)}>
              <Card class="border-2 border-dashed shadow-xs opacity-50 hover:opacity-100 hover:bg-base-200 h-full transition-all">
                <span class="text-6xl mx-auto my-auto flex items-center justify-center h-full">+</span>
              </Card>
            </LiveRedirect>
          {/if}
          <InfiniteScroll id="shop-infinite-scroll" page={@offerings.page_number} load_more="load_more" />
        </div>
      {#elseif @studio.archived_at}
        <div class="w-full mx-auto md:bg-base-300">
          <div class="max-w-prose w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
            <h1 class="text-2xl">
              Studio Archived
            </h1>
            <div class="divider" />
            <p>This studio has been archived and will not be listed anywhere.</p>
            {#if @current_user_member?}
              <p>Do you want to unarchive it?</p>
              <Button click="unarchive_studio" label="Unarchive" />
            {/if}
          </div>
        </div>
      {#else}
        <div class="w-full mx-auto md:bg-base-300">
          <div class="max-w-prose w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
            <h1 class="text-2xl">
              Coming Soon
            </h1>
            <div class="divider" />
            {#if @current_user_member? && !@studio.stripe_details_submitted}
              <p>You need to onboard your studio on Stripe before it opens its doors.</p>
              <p>Note: If you've completed onboarding and still see this, try refreshing the page.</p>
              <div class="flex flex-row-reverse">
                <Link label="Onboard" to={@stripe_onboarding_url} class="btn btn-primary py-1 px-5 m-1" />
                <Button click="recheck_stripe" label="Recheck" class="btn-link" />
              </div>
            {#elseif @current_user_member? && !@studio.stripe_charges_enabled}
              <p>Details have been submitted to Stripe. Please wait while charges are enabled. This shouldn't take too long.</p>
              <Button click="recheck_stripe" label="Recheck" class="btn-link" />
            {#else}
              <p>This studio is still working on opening its doors. Check back in soon!</p>
            {/if}
          </div>
        </div>
      {/if}
    </StudioLayout>
    """
  end
end
