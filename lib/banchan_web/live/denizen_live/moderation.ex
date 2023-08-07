defmodule BanchanWeb.DenizenLive.Moderation do
  @moduledoc """
  Admin-level user editing, such as changing roles, disabling, and such.
  """
  use BanchanWeb, :live_view

  alias Surface.Components.Form

  alias Banchan.Accounts
  alias Banchan.Accounts.{DisableHistory, User}
  alias Banchan.Repo

  alias BanchanWeb.Components.Form.{
    DateTimeLocalInput,
    MultipleSelect,
    QuillInput,
    Submit
  }

  alias BanchanWeb.Components.{Avatar, Layout, Markdown, UserHandle}
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, _session, socket) do
    user =
      Accounts.get_user_by_handle!(handle)
      |> Repo.preload([:disable_info, disable_history: [:disabled_by, :lifted_by]])

    if :admin in socket.assigns.current_user.roles ||
         (:mod in socket.assigns.current_user.roles && :admin not in user.roles) do
      socket =
        socket
        |> assign(
          user: user,
          roles: [Mod: :mod, Admin: :admin, Artist: :artist],
          changeset: User.admin_changeset(socket.assigns.current_user, user)
        )

      socket =
        if user.disable_info do
          socket
          |> assign(enable_changeset: DisableHistory.enable_changeset(%DisableHistory{}, %{}))
        else
          socket
          |> assign(disable_changeset: DisableHistory.disable_changeset(%DisableHistory{}, %{}))
        end

      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, "You are not authorized to access this page.")
       |> push_navigate(to: Routes.denizen_show_path(Endpoint, :show, handle))}
    end
  end

  @impl true
  def handle_event("change", %{"user" => user}, socket) do
    changeset =
      User.admin_changeset(
        socket.assigns.current_user,
        socket.assigns.user,
        user |> Map.put("roles", Map.get(user, "roles", []))
      )
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(changeset: changeset)}
  end

  @impl true
  def handle_event("submit", %{"user" => user}, socket) do
    case Accounts.update_admin_fields(
           socket.assigns.current_user,
           socket.assigns.user,
           user |> Map.put("roles", Map.get(user, "roles", []))
         ) do
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(changeset: changeset)}

      {:ok, user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User updated.")
         |> push_navigate(to: Routes.denizen_show_path(Endpoint, :show, user.handle))}
    end
  end

  @impl true
  def handle_event("change_disable", val, socket) do
    changeset =
      %DisableHistory{}
      |> DisableHistory.disable_changeset(val["disable"])
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(disable_changeset: changeset)}
  end

  @impl true
  def handle_event("submit_disable", val, socket) do
    case Accounts.disable_user(
           socket.assigns.current_user,
           socket.assigns.user,
           val["disable"]
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User disabled.")
         |> push_navigate(
           to: Routes.denizen_show_path(Endpoint, :show, socket.assigns.user.handle)
         )}

      {:error, changeset} ->
        {:noreply, socket |> assign(disable_changeset: changeset)}
    end
  end

  @impl true
  def handle_event("change_enable", val, socket) do
    changeset =
      %DisableHistory{}
      |> DisableHistory.enable_changeset(val["enable"])
      |> Map.put(:action, :update)

    {:noreply, socket |> assign(enable_changeset: changeset)}
  end

  @impl true
  def handle_event("submit_enable", val, socket) do
    case Accounts.enable_user(
           socket.assigns.current_user,
           socket.assigns.user,
           val["enable"]["lifted_reason"]
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "User enabled.")
         |> push_navigate(
           to: Routes.denizen_show_path(Endpoint, :show, socket.assigns.user.handle)
         )}

      {:error, changeset} ->
        {:noreply, socket |> assign(enable_changeset: changeset)}
    end
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout flashes={@flash} padding={0} context={:admin}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-xl w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Form as={:user} for={@changeset} change="change" submit="submit">
            <div class="text-xl">
              Manage User @{@user.handle}
            </div>
            <MultipleSelect
              info="User roles to apply to this user. Can select multiple items."
              name={:roles}
              options={@roles}
            />
            <QuillInput
              id="moderation_notes"
              info="These are internal notes for admins and moderators about this user. They are not displayed to the user or anyone else."
              name={:moderation_notes}
            />
            <Submit label="Save" changeset={@changeset} />
          </Form>
          <div class="divider" />
          {#if @user.disable_info}
            <Form as={:enable} for={@enable_changeset} change="change_enable" submit="submit_enable">
              <div class="text-xl">
                Re-enable @{@user.handle}
              </div>
              <QuillInput id="lifted_reason" name={:lifted_reason} opts={required: true} />
              <Submit label="Enable" changeset={@enable_changeset} />
            </Form>
          {#else}
            <Form as={:disable} for={@disable_changeset} change="change_disable" submit="submit_disable">
              <div class="text-xl">
                Disable @{@user.handle}
              </div>
              <QuillInput id="disabled_reason" name={:disabled_reason} opts={required: true} />
              <DateTimeLocalInput name={:disabled_until} />
              <Submit label="Disable" changeset={@disable_changeset} />
            </Form>
          {/if}
          <div :if={!Enum.empty?(@user.disable_history)} class="divider" />
          <div class="overflow-x-auto">
            <table class="table border table-zebra border-base-content border-opacity-10 rounded w-full">
              <thead>
                <tr>
                  <th>Disabled At</th>
                  <th>Disabled Reason</th>
                  <th>Lifted At</th>
                  <th>Lifted Reason</th>
                </tr>
              </thead>
              {#for item <- @user.disable_history}
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
