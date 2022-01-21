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
      <div class="card shadow bg-base-200 card-bordered text-base-content">
        <div class="card-body">
          <h1 class="text-2xl card-title">Edit Profile for @{@user.handle}</h1>
          <Form for={@changeset} change="change" submit="submit">
            <Field class="field" name={:handle}>
              <Label class="label" />
              <div class="control has-icons-left">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={
                      "input",
                      "input-primary",
                      "input-bordered",
                      "input-sm",
                      "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
                    }
                    opts={required: true}
                  />
                </InputContext>
                <span class="icon is-small is-left">
                  <i class="fas fa-at" />
                </span>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <Field class="field" name={:name}>
              <Label class="label" />
              <div class="control has-icons-left">
                <InputContext :let={form: form, field: field}>
                  <TextInput
                    class={
                      "input",
                      "input-primary",
                      "input-bordered",
                      "input-sm",
                      "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
                    }
                    opts={required: true}
                  />
                </InputContext>
                <span class="icon is-small is-left">
                  <i class="fas fa-user" />
                </span>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <Field class="field" name={:bio}>
              <Label class="label" />
              <div class="control">
                <InputContext :let={form: form, field: field}>
                  <TextArea
                    class={
                      "textarea",
                      "textarea-bordered",
                      "textarea-primary",
                      "h-24",
                      "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))
                    }
                    opts={required: true}
                  />
                </InputContext>
              </div>
              <ErrorTag class="help is-danger" />
            </Field>
            <div class="field">
              <div class="control text-base-content m-1">
                <Submit
                  class="btn btn-secondary rounded-full py-1 px-5"
                  label="Save"
                  opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}
                />
              </div>
            </div>
          </Form>
        </div>
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
