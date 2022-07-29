defmodule BanchanWeb.StudioLive.Settings do
  @moduledoc """
  Banchan studio settings editing.
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.{Form, Link}

  alias Banchan.Studios
  alias Banchan.Studios.{Notifications, Studio}

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.Button

  alias BanchanWeb.Components.Form.{
    Checkbox,
    MarkdownInput,
    MultipleSelect,
    Select,
    Submit
  }

  alias BanchanWeb.StudioLive.Components.{Blocklist, StudioLayout}

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, true, false)

    currencies =
      Studios.Common.supported_currencies()
      |> Enum.map(fn currency ->
        %{name: name, symbol: symbol} = Money.Currency.get(currency)
        {:"#{name} (#{symbol})", currency}
      end)

    {:ok,
     assign(socket,
       changeset: Studio.settings_changeset(socket.assigns.studio, %{}),
       currencies: [{:"Currencies...", nil} | currencies],
       subscribed?:
         Notifications.user_subscribed?(socket.assigns.current_user, socket.assigns.studio)
     )}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def handle_event("toggle_subscribed", _, socket) do
    if socket.assigns.subscribed? do
      Notifications.unsubscribe_user!(socket.assigns.current_user, socket.assigns.studio)
    else
      Notifications.subscribe_user!(socket.assigns.current_user, socket.assigns.studio)
    end

    {:noreply, assign(socket, subscribed?: !socket.assigns.subscribed?)}
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  def handle_event("submit", val, socket) do
    case Studios.update_studio_settings(
           socket.assigns.current_user,
           socket.assigns.studio,
           socket.assigns.current_user_member?,
           val["studio"]
         ) do
      {:ok, studio} ->
        socket =
          socket
          |> assign(changeset: Studio.settings_changeset(studio, %{}), studio: studio)
          |> put_flash(:info, "Settings updated")
          |> push_redirect(to: Routes.studio_settings_path(Endpoint, :show, studio.handle))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to edit this studio")
         |> push_redirect(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.studio
      |> Studio.settings_changeset(val["studio"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  def handle_info(%{event: "follower_count_changed", payload: new_count}, socket) do
    {:noreply, socket |> assign(followers: new_count)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout
      id="studio-layout"
      current_user={@current_user}
      flashes={@flash}
      studio={@studio}
      followers={@followers}
      current_user_member?={@current_user_member?}
      tab={:settings}
      padding={0}
      uri={@uri}
    >
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <h2 class="text-xl py-6">Notifications</h2>
          <div class="pb-6">Manage default notification settings for this studio. For example, whether to receive notifications for new commission requests.</div>
          <Button click="toggle_subscribed">
            {#if @subscribed?}
              Unsubscribe
            {#else}
              Subscribe
            {/if}
          </Button>

          <div class="divider" />

          <h2 class="text-xl py-6">Stripe Dashboard</h2>
          <div class="pb-6">
            You can manage your Stripe account details, such as your bank account, and see stats on previous payouts, over on your Stripe Express Dashboard.
          </div>
          <Link
            label="Go to Dashboard"
            class="btn btn-primary"
            to={Routes.stripe_dashboard_path(Endpoint, :dashboard, @studio.handle)}
          />

          <div class="divider" />

          <h2 class="text-xl py-6">Edit Studio Settings</h2>
          <Form class="flex flex-col gap-2" for={@changeset} change="change" submit="submit">
            <Checkbox
              name={:mature}
              label="Mature"
              info="Mark this studio as exclusively for mature content. You can still make indiviual mature offerings if this is unchecked."
            />
            <Select
              name={:default_currency}
              info="Default currency to display in currencies dropdown when entering invoice amounts."
              options={@currencies}
              opts={required: true}
            />
            <MultipleSelect
              name={:payment_currencies}
              info="Available currencies for invoicing purposes."
              options={@currencies}
              opts={required: true}
            />
            <MarkdownInput
              id="default-terms"
              info="Default Terms of Service to display to users, when an offering hasn't configured its own."
              name={:default_terms}
            />
            <MarkdownInput
              id="default-template"
              info="Default commission submission template, when an offering hasn't configured its own."
              name={:default_template}
            />
            <Submit label="Save" />
          </Form>

          <div class="divider" />

          <div class="h-40 overflow-auto">
            <Blocklist id="studio-blocklist" studio={@studio} />
          </div>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
