defmodule BanchanWeb.LoginLive do
  @moduledoc """
  Account Login
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{ErrorTag, Field, Label, PasswordInput, Submit, TextInput}

  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket, false)

    {:ok,
     assign(socket,
       changeset: User.login_changeset(%Banchan.Accounts.User{}, %{}),
       trigger_submit: false
     )}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1>Log in</h1>
      <Form for={@changeset} action={Routes.user_session_path(Endpoint, :create)} change="change" submit="submit" trigger_action={@trigger_submit}>
        <Field name={:email}>
          <Label />
          <TextInput />
          <ErrorTag />
        </Field>
        <Field name={:password}>
          <Label />
          <PasswordInput />
          <ErrorTag />
        </Field>
        <Submit label="Log in" opts={disabled: Enum.empty?(@changeset.changes) || !@changeset.valid?}/>
      </Form>
    </Layout>
    """
  end

  @impl true
  def handle_event("change", val, socket) do
    changeset =
      %Banchan.Accounts.User{}
      |> User.login_changeset(val["user"])
      |> Map.put(:action, :update)

    socket = assign(socket, changeset: changeset)
    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", val, socket) do
    changeset =
      %Banchan.Accounts.User{}
      |> User.login_changeset(val["user"])

    {:noreply, assign(socket, changeset: changeset, trigger_submit: true)}
  end
end
