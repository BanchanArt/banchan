defmodule BanchanWeb.StudioLive.Shop do
  @moduledoc """
  LiveView for viewing individual Studios
  """
  use BanchanWeb, :surface_view

  alias Banchan.Studios

  alias Surface.Components.LiveRedirect

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.{Button, Card}
  alias BanchanWeb.Endpoint
  alias BanchanWeb.StudioLive.Components.{OfferingCard, StudioLayout}

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)
    studio = socket.assigns.studio
    members = Studios.list_studio_members(studio)
    offerings = Studios.list_studio_offerings(studio, socket.assigns.current_user_member?)

    Studios.subscribe_to_stripe_state(studio)

    stripe_onboarding_url =
      if !Studios.charges_enabled?(studio) && socket.assigns.current_user_member? do
        Routes.stripe_account_path(Endpoint, :account_link, studio.handle)
      else
        nil
      end

    # TODO: This page does a TON of requests right now (partly because of
    # OfferingCard). This should be replaced with a single "general" query
    # that picks up everything we need for this listing.
    {:ok,
     assign(socket,
       members: members,
       offerings: offerings,
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

  @impl true
  def handle_event("recheck_stripe", _, socket) do
    # No need to refresh the studio here. It'll get reloaded by the PubSub event(s)
    Studios.charges_enabled?(socket.assigns.studio, true)
    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      id="studio-layout"
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      current_user_member?={@current_user_member?}
      tab={:shop}
      uri={@uri}
    >
      {#if Studios.charges_enabled?(@studio)}
        <div class="flex flex-wrap pt-4 items-stretch">
          {#for offering <- @offerings}
            <div class="basis-full md:basis-1/3 p-2 max-w-sm h-128">
              <OfferingCard
                id={"offering-" <> offering.type}
                current_user={@current_user}
                current_user_member?={@current_user_member?}
                studio={@studio}
                offering={offering}
              />
            </div>
          {#else}
            This shop has no offerings currently available. Check back in later!
          {/for}
          {#if @current_user_member?}
            <div class="basis-full md:basis-1/3 p-2 max-w-sm h-128">
              <LiveRedirect to={Routes.studio_offerings_new_path(Endpoint, :new, @studio.handle)}>
                <Card class="border-2 border-dashed shadow-xs opacity-50 hover:opacity-100 h-full">
                  <span class="text-6xl mx-auto my-auto flex items-center justify-center h-full">+</span>
                </Card>
              </LiveRedirect>
            </div>
          {/if}
        </div>
      {#elseif @current_user_member? && !@studio.stripe_details_submitted}
        <p>You need to <a class="hover:underline font-bold" href={@stripe_onboarding_url}>onboard your studio on Stripe</a>

          <Button click="recheck_stripe" label="Recheck" />
        </p>
      {#elseif @current_user_member? && !@studio.stripe_charges_enabled}
        <p>Details have been submitted to Stripe. Please wait while charges are enabled.

          <Button click="recheck_stripe" label="Recheck" />
        </p>
      {#else}
        <p>This studio is still working on opening its doors. Check back in soon!</p>
      {/if}
    </StudioLayout>
    """
  end
end
