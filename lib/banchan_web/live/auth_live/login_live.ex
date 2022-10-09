defmodule BanchanWeb.LoginLive do
  @moduledoc """
  Account Login
  """
  use BanchanWeb, :surface_view
  on_mount BanchanWeb.UserLiveAuth

  alias Surface.Components.{Form, Link, LiveRedirect}

  alias BanchanWeb.AuthLive.Components.AuthLayout
  alias BanchanWeb.Components.Form.{Checkbox, Submit, TextInput}
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
    socket = Context.put(socket, uri: uri, flash: socket.assigns.flash)
    {:noreply, socket |> assign(uri: uri)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <AuthLayout>
      <Form
        class="flex flex-col gap-4"
        for={@changeset}
        action={Routes.user_session_path(Endpoint, :create)}
        change="change"
        submit="submit"
        trigger_action={@trigger_submit}
      >
        <h1 class="text-2xl">Log in</h1>
        <TextInput name={:identifier} icon="at" label="Email or Handle" opts={required: true} />
        <TextInput name={:password} icon="lock" opts={required: true, type: :password} />
        <TextInput
          label="MFA Token"
          name={:mfa_token}
          icon="mobile-alt"
          opts={maxlength: 6, placeholder: "optional"}
        />
        <Checkbox name={:remember_me} label="Keep me logged in for 60 days." />
        <Submit class="w-full" changeset={@changeset} label="Log in" />
        <LiveRedirect class="link link-primary" to={Routes.forgot_password_path(Endpoint, :edit)}>
          Forgot your password?
        </LiveRedirect>
      </Form>
      <div class="divider">OR</div>
      <div class="flex flex-col gap-4">
        <div class="text-xl mx-auto">
          Sign in with...
        </div>
        <div class="flex flex-row gap-2 justify-center">
          <Link
            class="btn bg-twitter flex-1 text-xl"
            to={Routes.user_o_auth_path(Endpoint, :request, "twitter")}
          ><i class="px-2 fa-brands fa-twitter" /></Link>
          <Link
            class="btn bg-discord flex-1 text-xl"
            to={Routes.user_o_auth_path(Endpoint, :request, "discord")}
          ><i class="px-2 fa-brands fa-discord" /></Link>
          {!--
          # TODO: Re-enable when Google has approved our app (post-launch)
          <Link
            class="btn bg-google flex-1 text-xl"
            to={Routes.user_o_auth_path(Endpoint, :request, "google")}
          ><i class="px-2 fa-brands fa-google" /></Link>
          --}
        </div>
      </div>
      <div class="divider">OR</div>
      <div class="mx-auto">
        <LiveRedirect class="btn btn-link btn-sm w-full" to={Routes.register_path(Endpoint, :new)}>
          Register
        </LiveRedirect>
      </div>
    </AuthLayout>
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
