defmodule BanchanWeb.LoginLive do
  @moduledoc """
  Account Login
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{Checkbox, EmailInput, ErrorTag, Field, Label, Submit, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket, false)

    {:ok,
     assign(socket,
       changeset: User.login_changeset(%User{}, %{}),
       trigger_submit: false
     )}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl col-span-2">Log in</h1>
      <div class="grid grid-cols-2 gap-4 form-styling">
        <Form
          class="col-span-2"
          for={@changeset}
          action={Routes.user_session_path(Endpoint, :create)}
          change="change"
          submit="submit"
          trigger_action={@trigger_submit}
        >
          <Field class="field" name={:email}>
            <span class="icon is-small is-left">
              <Label class="label form-label-100" />
              <i class="fas fa-envelope" />
            </span>
            <div class="control">
              <InputContext :let={form: form, field: field}>
                <EmailInput
                  class={"input form-input-100", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:password}>
            <span class="icon is-small is-left">
              <Label class="label form-label" />
              <i class="fas fa-lock" />
            </span>
            <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input form-input-100", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true, type: :password}
                />
              </InputContext>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:remember_me}>
            <div class="control">
              <Label class="checkbox">
                <Checkbox class="form-checkbox-100" />
                Keep me logged in for 60 days
              </Label>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <div class="field">
            <div class="control">
              <Submit
                class="btn-base btn-amber"
                label="Log in"
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
      %User{}
      |> User.login_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    changeset =
      %User{}
      |> User.login_changeset(val["user"])

    {:noreply, assign(socket, changeset: changeset, trigger_submit: true)}
  end
end
