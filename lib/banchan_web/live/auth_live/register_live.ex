defmodule BanchanWeb.RegisterLive do
  @moduledoc """
  Account Registration
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  alias Banchan.Accounts
  alias Banchan.Accounts.User

  alias BanchanWeb.Components.Form.{EmailInput, TextInput}
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
      <h1 class="text-2xl">Register</h1>
      <div class="grid grid-cols-3 gap-4">
        <Form
          class="col-span-1"
          for={@changeset}
          action={Routes.user_registration_path(Endpoint, :create)}
          change="change"
          submit="submit"
          trigger_action={@trigger_submit}
        >
          <EmailInput name={:email} wrapper_class="has-icons-left" opts={required: true}>
            <:right>
              <span class="icon is-small is-left">
                <i class="fas fa-envelope" />
              </span>
            </:right>
          </EmailInput>
          <TextInput name={:password} wrapper_class="has-icons-left" opts={required: true, type: :password}>
            <:right>
              <span class="icon is-small is-left">
                <i class="fas fa-lock" />
              </span>
            </:right>
          </TextInput>
          <TextInput
            name={:password_confirmation}
            wrapper_class="has-icons-left"
            opts={required: true, type: :password}
          >
            <:right>
              <span class="icon is-small is-left">
                <i class="fas fa-lock" />
              </span>
            </:right>
          </TextInput>
          <div class="field">
            <div class="control">
              <Submit
                class="btn text-center rounded-full py-1 px-5 btn-secondary m-1"
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
