defmodule BanchanWeb.LoginLive do
  @moduledoc """
  Account Login
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.Submit

  alias BanchanWeb.Components.Form.{Checkbox, EmailInput, TextInput}
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
      <div class="card shadow bg-base-200 card-bordered text-base-content">
        <div class="card-body">
          <h1 class="text-2xl">Log in</h1>
          <Form
            class="col-span-1"
            for={@changeset}
            action={Routes.user_session_path(Endpoint, :create)}
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
            <Checkbox name={:remember_me}>Keep me logged in for 60 days.</Checkbox>
            <div class="field">
              <div class="control">
                <Submit
                  class="btn text-center rounded-full py-1 px-5 btn-secondary m-1"
                  label="Log in"
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
