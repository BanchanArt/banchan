defmodule BanchanWeb.RegisterLive do
  @moduledoc """
  Account Registration
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{EmailInput, ErrorTag, Field, Label, Submit, TextInput}

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
      <h1 class="title">Register</h1>
      <Form
        for={@changeset}
        action={Routes.user_registration_path(Endpoint, :create)}
        change="change"
        submit="submit"
        trigger_action={@trigger_submit}
      >
        <Field name={:email}>
          <Label />
          <EmailInput opts={required: true} />
          <ErrorTag />
        </Field>
        <Field name={:password}>
          <Label />
          <TextInput opts={required: true, type: :password} />
          <ErrorTag />
        </Field>
        <Field name={:password_confirmation}>
          <Label />
          <TextInput opts={required: true, type: :password} />
          <ErrorTag />
        </Field>
        <Submit label="Register" opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?} />
      </Form>
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
