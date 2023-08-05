defmodule BanchanWeb.StudioLive.Moderation do
  @moduledoc """
  Admin-level studio editing, such as changing platform fees, disabling, etc.
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Form

  alias Banchan.Repo
  alias Banchan.Studios
  alias Banchan.Studios.{Studio, StudioDisableHistory}

  import BanchanWeb.StudioLive.Helpers

  alias BanchanWeb.Components.{Avatar, Layout, Markdown, UserHandle}

  alias BanchanWeb.Components.Form.{
    DateTimeLocalInput,
    QuillInput,
    Submit,
    TextInput
  }

  alias BanchanWeb.Endpoint

  @impl true
  def mount(params, _session, socket) do
    socket = assign_studio_defaults(params, socket, false, false)

    socket =
      socket
      |> assign(
        studio:
          socket.assigns.studio
          |> Repo.preload(disable_history: [:disabled_by, :lifted_by])
      )

    if :admin in socket.assigns.current_user.roles || :mod in socket.assigns.current_user.roles do
      socket =
        socket
        |> assign(changeset: Studio.admin_changeset(socket.assigns.studio, %{}))

      socket =
        if socket.assigns.studio.disable_info do
          socket
          |> assign(
            enable_changeset: StudioDisableHistory.enable_changeset(%StudioDisableHistory{}, %{})
          )
        else
          socket
          |> assign(
            disable_changeset:
              StudioDisableHistory.disable_changeset(%StudioDisableHistory{}, %{})
          )
        end

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page.")
       |> push_navigate(
         to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
       )}
    end
  end

  @impl true
  def handle_event("change", %{"studio" => studio}, socket) do
    changeset =
      Studio.admin_changeset(socket.assigns.studio, studio)
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("submit", %{"studio" => studio}, socket) do
    case Studios.update_admin_fields(
           socket.assigns.current_user,
           socket.assigns.studio,
           studio
         ) do
      {:error, :unauthorized} ->
        {:noreply,
         socket
         |> put_flash(:error, "You are not authorized to perform this action.")
         |> push_navigate(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:ok, studio} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio updated.")
         |> push_navigate(to: Routes.studio_shop_path(Endpoint, :show, studio.handle))}
    end
  end

  @impl true
  def handle_event("change_disable", %{"disable" => disable}, socket) do
    changeset =
      %StudioDisableHistory{}
      |> StudioDisableHistory.disable_changeset(disable)
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(disable_changeset: changeset)}
  end

  @impl true
  def handle_event("submit_disable", %{"disable" => disable}, socket) do
    case Studios.disable_studio(
           socket.assigns.current_user,
           socket.assigns.studio,
           disable
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio disabled.")
         |> push_navigate(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, changeset} ->
        {:noreply, socket |> assign(disable_changeset: changeset)}
    end
  end

  @impl true
  def handle_event("change_enable", %{"enable" => enable}, socket) do
    changeset =
      %StudioDisableHistory{}
      |> StudioDisableHistory.enable_changeset(enable)
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(enable_changeset: changeset)}
  end

  @impl true
  def handle_event("submit_enable", %{"enable" => enable}, socket) do
    case Studios.enable_studio(
           socket.assigns.current_user,
           socket.assigns.studio,
           enable["lifted_reason"]
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Studio enabled.")
         |> push_navigate(
           to: Routes.studio_shop_path(Endpoint, :show, socket.assigns.studio.handle)
         )}

      {:error, changeset} ->
        {:noreply, socket |> assign(enable_changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} studio={@studio} context={:admin}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Form as={:studio} for={@changeset} change="change" submit="submit">
            <div class="text-xl">
              Manage {@studio.name}
            </div>
            <TextInput
              name={:platform_fee}
              info="Multiplier to use when calculating the platform fee paid by this studio for transactions."
            />
            <QuillInput
              id="moderation_notes"
              info="These are internal notes for admins and moderators about this user. They are not displayed to the user or anyone else."
              name={:moderation_notes}
            />
            <Submit class="mt-2" label="Save" changeset={@changeset} />
          </Form>
          <div class="divider" />
          {#if @studio.disable_info}
            <Form as={:enable} for={@enable_changeset} change="change_enable" submit="submit_enable">
              <div class="text-xl">
                Re-enable {@studio.name}
              </div>
              <QuillInput id="lifted_reason" name={:lifted_reason} opts={required: true} />
              <Submit class="my-2" label="Enable" changeset={@enable_changeset} />
            </Form>
          {#else}
            <Form as={:disable} for={@disable_changeset} change="change_disable" submit="submit_disable">
              <div class="text-xl">
                Disable {@studio.name}
              </div>
              <QuillInput id="disabled_reason" name={:disabled_reason} opts={required: true} />
              <DateTimeLocalInput name={:disabled_until} />
              <Submit class="my-2" label="Disable" changeset={@disable_changeset} />
            </Form>
          {/if}
          <div :if={!Enum.empty?(@studio.disable_history)} class="divider" />
          <div class="overflow-x-auto">
            <table class="table table-zebra w-full">
              <thead>
                <tr>
                  <th>Disabled At</th>
                  <th>Disabled Reason</th>
                  <th>Lifted At</th>
                  <th>Lifted Reason</th>
                </tr>
              </thead>
              {#for item <- @studio.disable_history}
                <tr>
                  <td
                    class="flex flex-col"
                    title={item.disabled_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}
                  >
                    {item.disabled_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}
                    {#if item.disabled_until}
                      <div class="badge badge-sm">Until {item.disabled_until |> Timex.to_datetime() |> Timex.format!("{RFC822}")}</div>
                    {/if}
                    <div class="text-sm">
                      By <Avatar class="w-4" user={item.disabled_by} /> <UserHandle user={item.disabled_by} />
                    </div>
                  </td>
                  <td><Markdown content={item.disabled_reason} /></td>
                  <td title={item.lifted_at && item.lifted_at |> Timex.to_datetime() |> Timex.format!("{RFC822}")}>
                    {item.lifted_at && item.lifted_at |> Timex.to_datetime() |> Timex.format!("{relative}", :relative)}
                    {#if item.lifted_by}
                      <div class="text-sm">
                        By <Avatar class="w-4" user={item.lifted_by} /> <UserHandle user={item.lifted_by} />
                      </div>
                    {/if}
                  </td>
                  <td><Markdown content={item.lifted_reason} /></td>
                </tr>
              {/for}
            </table>
          </div>
        </div>
      </div>
    </Layout>
    """
  end
end
