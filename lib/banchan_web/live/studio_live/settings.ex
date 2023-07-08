defmodule BanchanWeb.StudioLive.Settings do
  @moduledoc """
  Banchan studio settings editing.
  """
  use BanchanWeb, :live_view

  alias Surface.Components.{Form, Link}

  alias Banchan.Studios
  alias Banchan.Studios.{Notifications, Studio}

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.{Button, Collapse}

  alias BanchanWeb.Components.Form.{
    Checkbox,
    MarkdownInput,
    MultipleSelect,
    Select,
    Submit,
    TextInput
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
           val["studio"]
         ) do
      {:ok, studio} ->
        socket =
          socket
          |> assign(changeset: Studio.settings_changeset(studio, %{}), studio: studio)
          |> put_flash(:info, "Settings updated")
          |> push_navigate(to: Routes.studio_settings_path(Endpoint, :show, studio.handle))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to edit this studio")
         |> push_navigate(
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

  def handle_event("archive_studio", _, socket) do
    case Studios.archive_studio(
           socket.assigns.current_user,
           socket.assigns.studio
         ) do
      {:ok, _studio} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio archived")
         |> push_navigate(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "An unexpected error occurred. Please try again later.")
         |> push_navigate(
           to: Routes.studio_settings_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  def handle_event("unarchive_studio", _, socket) do
    case Studios.unarchive_studio(
           socket.assigns.current_user,
           socket.assigns.studio
         ) do
      {:ok, _studio} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio unarchived")
         |> push_navigate(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "An unexpected error occurred. Please try again later.")
         |> push_navigate(
           to: Routes.studio_settings_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  def handle_event("delete_studio", val, socket) do
    case Studios.delete_studio(
           socket.assigns.current_user,
           socket.assigns.studio,
           val["delete"] && val["delete"]["password"]
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio has been successfully deleted.")
         |> push_navigate(to: Routes.home_path(Endpoint, :index))}

      {:error, :pending_funds} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Can't delete a studio when funds are still pending either in invoices or in payouts."
         )
         |> push_navigate(
           to: Routes.studio_settings_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, :invalid_password} ->
        {:noreply,
         socket
         |> put_flash(:error, "Invalid password when trying to delete studio. Please try again.")
         |> push_navigate(
           to: Routes.studio_settings_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Something went wrong while marking the studio for deletion. Please try again later."
         )
         |> push_navigate(
           to: Routes.studio_settings_path(Endpoint, :show, socket.assigns.studio.handle)
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <StudioLayout flashes={@flash} id="studio-layout" studio={@studio} tab={:settings} padding={0}>
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
            opts={target: "_blank", rel: "noopener noreferrer"}
          />

          <div class="divider" />

          <h2 class="text-xl py-6">Edit Studio Settings</h2>
          <Form class="flex flex-col gap-2" for={@changeset} change="change" submit="submit">
            {#if Application.get_env(:banchan, :mature_content_enabled?)}
              <Checkbox
                name={:mature}
                label="Mature"
                info="Mark this studio as exclusively for mature content. You can still make indiviual mature offerings if this is unchecked."
              />
            {/if}
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
            <div class="text-xl py-4">Blocklist</div>
            <Blocklist id="studio-blocklist" studio={@studio} />
          </div>

          <div class="divider" />

          {#if @studio.archived_at}
            <Collapse id="archive-studio-collapse" class="w-full">
              <:header>
                <div class="font-semibold text-error">Archive</div>
              </:header>
              <div class="prose">
                <p>This studio is currently archived. This is a reversible operation that hides it and prevents it from being accessed by non-members.</p>
                <p>Do you want to bring it back?</p>
              </div>
              <Button click="unarchive_studio" class="w-full btn-primary" label="Confirm" />
            </Collapse>
          {#else}
            <Collapse id="archive-studio-collapse" class="w-full">
              <:header>
                <div class="font-semibold text-error">Archive</div>
              </:header>
              <div class="prose">
                <p>Archiving is a reversible operation that unlists the studio and prevents new commissions, but allows you to retain access to historical information from commissions and payouts. It's also doable while there's still money pending.</p>
                <p>Are you sure you want to archive this studio?</p>
              </div>
              <Button click="archive_studio" class="w-full btn-error" label="Confirm" />
            </Collapse>
          {/if}

          <div class="divider" />

          <Collapse id="delete-studio-collapse" class="w-full">
            <:header>
              <div class="font-semibold text-error">Delete</div>
            </:header>
            <Form class="flex flex-col gap-4" for={%{}} as={:delete} submit="delete_studio">
              <div class="prose">
                <p>This operation <strong>can't be reversed</strong>. The studio's handle will also not be available for the next 30 days.</p>
                <p>You will no longer have access to payout records, and all current open invoices will be canceled.</p>
                <p>Additionally, this operation will not succeed if you still have money in your account, or there are payments pending processing.</p>
                <p>Are you sure you want to delete this studio?</p>
              </div>
              {#if @current_user.email}
                <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
              {/if}
              <Submit class="w-full btn-error" label="Confirm" />
            </Form>
          </Collapse>
        </div>
      </div>
    </StudioLayout>
    """
  end
end
