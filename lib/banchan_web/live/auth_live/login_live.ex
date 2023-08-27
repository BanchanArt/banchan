defmodule BanchanWeb.LoginLive do
  @moduledoc """
  Account Login
  """
  use BanchanWeb, :live_view
  on_mount(BanchanWeb.UserLiveAuth)

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
  def render(assigns) do
    ~F"""
    <AuthLayout flashes={@flash}>
      <Form
        class="flex flex-col gap-4"
        for={@changeset}
        action={Routes.user_session_path(Endpoint, :create)}
        change="change"
        submit="submit"
        trigger_action={@trigger_submit}
      >
        <h1 class="text-2xl">Log in</h1>
        <TextInput
          name={:identifier}
          icon="at-sign"
          label="Email or Handle"
          opts={required: true, placeholder: "youremail@example.com"}
        />
        <TextInput
          name={:password}
          icon="lock"
          opts={required: true, type: :password, placeholder: "your_secure_password"}
        />
        <TextInput
          label="MFA Token"
          name={:mfa_token}
          icon="smartphone"
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
        <div class="mx-auto text-xl">
          Sign in with...
        </div>
        <div class="flex flex-row justify-center gap-2">
          <Link
            class="flex flex-row items-center flex-1 gap-2 text-xl btn bg-discord border-discord hover:bg-discord hover:border-discord focus:ring-primary focus:outline-none focus:ring"
            to={Routes.user_o_auth_path(Endpoint, :request, "discord")}
          >
            <svg role="img" viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg">
              <title>Discord</title>
              <path
                fill="currentColor"
                d="M20.317 4.3698a19.7913 19.7913 0 00-4.8851-1.5152.0741.0741 0 00-.0785.0371c-.211.3753-.4447.8648-.6083 1.2495-1.8447-.2762-3.68-.2762-5.4868 0-.1636-.3933-.4058-.8742-.6177-1.2495a.077.077 0 00-.0785-.037 19.7363 19.7363 0 00-4.8852 1.515.0699.0699 0 00-.0321.0277C.5334 9.0458-.319 13.5799.0992 18.0578a.0824.0824 0 00.0312.0561c2.0528 1.5076 4.0413 2.4228 5.9929 3.0294a.0777.0777 0 00.0842-.0276c.4616-.6304.8731-1.2952 1.226-1.9942a.076.076 0 00-.0416-.1057c-.6528-.2476-1.2743-.5495-1.8722-.8923a.077.077 0 01-.0076-.1277c.1258-.0943.2517-.1923.3718-.2914a.0743.0743 0 01.0776-.0105c3.9278 1.7933 8.18 1.7933 12.0614 0a.0739.0739 0 01.0785.0095c.1202.099.246.1981.3728.2924a.077.077 0 01-.0066.1276 12.2986 12.2986 0 01-1.873.8914.0766.0766 0 00-.0407.1067c.3604.698.7719 1.3628 1.225 1.9932a.076.076 0 00.0842.0286c1.961-.6067 3.9495-1.5219 6.0023-3.0294a.077.077 0 00.0313-.0552c.5004-5.177-.8382-9.6739-3.5485-13.6604a.061.061 0 00-.0312-.0286zM8.02 15.3312c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9555-2.4189 2.157-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.9555 2.4189-2.1569 2.4189zm7.9748 0c-1.1825 0-2.1569-1.0857-2.1569-2.419 0-1.3332.9554-2.4189 2.1569-2.4189 1.2108 0 2.1757 1.0952 2.1568 2.419 0 1.3332-.946 2.4189-2.1568 2.4189Z"
              />
            </svg>
            <span class="text-base font-semibold normal-case">Discord</span>
          </Link>
          <Link
            class="flex flex-row items-center flex-1 gap-2 text-xl btn bg-google border-google hover:bg-google hover:border-google focus:ring-primary focus:outline-none focus:ring"
            to={Routes.user_o_auth_path(Endpoint, :request, "google")}
          >
            <svg role="img" viewBox="0 0 24 24" width="16" height="16" xmlns="http://www.w3.org/2000/svg">
              <title>Google</title>
              <path
                fill="currentColor"
                d="M12.48 10.92v3.28h7.84c-.24 1.84-.853 3.187-1.787 4.133-1.147 1.147-2.933 2.4-6.053 2.4-4.827 0-8.6-3.893-8.6-8.72s3.773-8.72 8.6-8.72c2.6 0 4.507 1.027 5.907 2.347l2.307-2.307C18.747 1.44 16.133 0 12.48 0 5.867 0 .307 5.387.307 12s5.56 12 12.173 12c3.573 0 6.267-1.173 8.373-3.36 2.16-2.16 2.84-5.213 2.84-7.667 0-.76-.053-1.467-.173-2.053H12.48z"
              />
            </svg>
            <span class="text-base font-semibold normal-case">Google</span>
          </Link>
        </div>
      </div>
      <div class="divider">OR</div>
      <div class="mx-auto">
        <LiveRedirect class="w-full btn btn-link btn-sm" to={Routes.register_path(Endpoint, :new)}>
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
