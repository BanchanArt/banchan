defmodule BanchanWeb.RegisterLive do
  @moduledoc """
  Account Registration
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{EmailInput, ErrorTag, Field, Label, Submit, TextInput}
  alias Surface.Components.Form.Input.InputContext

  alias Banchan.Accounts
  alias Banchan.Accounts.User
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket, false)

    {:ok,
     assign(socket,
       # For some reason, the tests for this aren't actually showing form
       # errors and I don't know why. It's not a big deal, because unless
       # someone is manually posting to the controller, they're very very
       # unlikely to see any errors? I _think_?
       changeset: Accounts.change_user_registration(%User{}, session),
       trigger_submit: false
     )}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="text-2xl">Register</h1> <div class="grid grid-cols-3 gap-4">
        <Form
          class="col-span-1"
          for={@changeset}
          action={Routes.user_registration_path(Endpoint, :create)}
          change="change"
          submit="submit"
          trigger_action={@trigger_submit}
        >
          <Field class="field" name={:email}>
            <Label class="label" /> <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <EmailInput
                  class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true}
                />
              </InputContext>
              <span class="icon is-small is-left">
                <i class="fas fa-envelope" />
              </span>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:password}>
            <Label class="label" /> <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true, type: :password}
                />
              </InputContext>
              <span class="icon is-small is-left">
                <i class="fas fa-lock" />
              </span>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <Field class="field" name={:password_confirmation}>
            <Label class="label" /> <div class="control has-icons-left">
              <InputContext :let={form: form, field: field}>
                <TextInput
                  class={"input", "is-danger": !Enum.empty?(Keyword.get_values(form.errors, field))}
                  opts={required: true, type: :password}
                />
              </InputContext>
              <span class="icon is-small is-left">
                <i class="fas fa-lock" />
              </span>
            </div>
            <ErrorTag class="help is-danger" />
          </Field>
          <div class="field">
            <div class="control">
              <Submit
                class="text-center rounded-full py-1 px-5 bg-amber-200 text-black m-1"
                label="Register"
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
      |> Accounts.change_user_registration(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    changeset =
      %User{}
      |> Accounts.change_user_registration(val["user"])

    {:noreply, assign(socket, changeset: changeset, trigger_submit: true)}
  end
end
