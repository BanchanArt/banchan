defmodule BanchanWeb.DenizenLive.Edit do
  @moduledoc """
  Banchan user profile pages
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, Submit, TextArea, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Accounts
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(%{"handle" => handle}, session, socket) do
    socket = assign_defaults(session, socket)
    user = Accounts.get_user_by_handle!(handle)
    {:ok, assign(socket, user: user, changeset: User.profile_changeset(user))}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Edit Profile</h1>
      <h2 class="text-xl">@{@user.handle}</h2>
      <div class="grid grid-cols-2 gap-4 form-styling">
        <Form class="col-span-2" for={@changeset} change="change" submit="submit">
          <Field class="field" name={:handle}>
            <span class="icon is-small is-left">
              <Label class="label form-label-100" />
              <i class="fas fa-at" />
            </span>
            <div class="control">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input form-input-100", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:name}>
            <span class="icon is-small is-left">
              <Label class="label form-label-100" />
              <i class="fas fa-user" />
            </span>

            <div class="control">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input form-input-100", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:bio}>
            <Label class="label form-label-100" />
            <div class="control">
              <InputContext :let={form: form, field: field}>
                <TextArea
                  class={"textarea form-textarea-100", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <div class="field">
            <div class="control text-black m-1">
              <Submit
                class="btn-base btn-amber"
                label="Save"
                opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
              />
            </div>
          </div>
        </Form>
      </div>
    </Layout>
    """
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      socket.assigns.user
      |> User.profile_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    case Accounts.update_user_profile(socket.assigns.user, val["user"]) do
      {:ok, user} ->
        socket = assign(socket, changeset: User.profile_changeset(user), user: user)
        socket = put_flash(socket, :info, "Profile updated")

        {:noreply,
         push_redirect(socket, to: Routes.denizen_show_path(Endpoint, :show, user.handle))}

      other ->
        other
    end
  end
end
