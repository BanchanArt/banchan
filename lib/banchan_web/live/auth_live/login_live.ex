defmodule BanchanWeb.LoginLive do
  @moduledoc """
  Account Login
  """
  use BanchanWeb, :surface_view
  on_mount BanchanWeb.UserLiveAuth

  alias Surface.Components.{Form, LiveRedirect}

  alias BanchanWeb.Components.Form.{Checkbox, EmailInput, Submit, TextInput}
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       changeset: User.login_changeset(%User{}, %{}),
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
            action={Routes.user_session_path(Endpoint, :create)}
            change="change"
            submit="submit"
            trigger_action={@trigger_submit}
          >
            <h1 class="text-2xl mx-auto">Log in</h1>
            <EmailInput name={:email} icon="envelope" opts={required: true} />
            <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
            <TextInput
              label="MFA Token"
              name={:mfa_token}
              icon="mobile-alt"
              opts={maxlength: 6, placeholder: "optional"}
            />
            <Checkbox name={:remember_me}>Keep me logged in for 60 days.</Checkbox>
            <Submit class="w-full" changeset={@changeset} label="Log in" />
          </Form>
          <div class="divider">OR</div>
          <div class="mx-auto">
            <LiveRedirect class="btn btn-link btn-sm w-full" to={Routes.register_path(Endpoint, :new)}>
              Register
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
