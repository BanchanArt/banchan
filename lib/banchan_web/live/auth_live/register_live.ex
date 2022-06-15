defmodule BanchanWeb.RegisterLive do
  @moduledoc """
  Account Registration
  """
  use BanchanWeb, :surface_view
  on_mount BanchanWeb.UserLiveAuth

  alias Surface.Components.{Form, LiveRedirect}

  alias Banchan.Accounts
  alias Banchan.Accounts.User

  alias BanchanWeb.Components.Form.{EmailInput, Submit, TextInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
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
  def handle_params(_params, uri, socket) do
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout uri={@uri} padding="0" drawer={false} current_user={@current_user} flashes={@flash}>
      <div class="w-full md:bg-base-300">
        <div class="max-w-sm w-full rounded-xl p-10 mx-auto md:my-10 bg-base-100">
          <Form
            class="flex flex-col gap-4"
            for={@changeset}
            action={Routes.user_registration_path(Endpoint, :create)}
            change="change"
            submit="submit"
            trigger_action={@trigger_submit}
          >
            <h1 class="text-2xl mx-auto">Register</h1>
            <EmailInput name={:email} icon="envelope" opts={required: true} />
            <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
            <TextInput
              name={:password_confirmation}
              label="Confirm Password"
              icon="lock"
              opts={required: true, type: :password}
            />
            <Submit class="w-full" changeset={@changeset} label="Register" />
          </Form>
          <div class="divider">OR</div>
          <div class="mx-auto">
            <LiveRedirect class="btn btn-link btn-sm w-full" to={Routes.login_path(Endpoint, :new)}>
              Log In
            </LiveRedirect>
          </div>
        </div>
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
