defmodule BanchanWeb.RegisterLive do
  @moduledoc """
  Account Registration
  """
  use BanchanWeb, :live_view
  on_mount BanchanWeb.UserLiveAuth

  alias Surface.Components.{Form, Link, LiveRedirect}

  alias Banchan.Accounts
  alias Banchan.Accounts.User

  alias BanchanWeb.AuthLive.Components.AuthLayout
  alias BanchanWeb.Components.Form.{EmailInput, Submit, TextInput}
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

  @impl true
  def render(assigns) do
    ~F"""
    <AuthLayout flashes={@flash}>
      <Form
        class="flex flex-col gap-4"
        for={@changeset}
        action={Routes.user_registration_path(Endpoint, :create)}
        change="change"
        submit="submit"
        trigger_action={@trigger_submit}
      >
        <h1 class="text-2xl">Register</h1>
        <TextInput
          name={:handle}
          info="Your unique @handle that can be used to refer to you."
          icon="at"
          opts={required: true}
        />
        <EmailInput
          name={:email}
          info="A valid email address. You'll need to confirm this."
          icon="envelope"
          opts={required: true}
        />
        <TextInput
          name={:password}
          info="Your new password. Must be between 12 and 80 characters."
          icon="lock"
          opts={required: true, type: :password}
        />
        <TextInput
          name={:password_confirmation}
          label="Confirm Password"
          info="Must match your password above!"
          icon="lock"
          opts={required: true, type: :password}
        />
        <Submit class="w-full" changeset={@changeset} label="Register" />
      </Form>
      <div class="divider">OR</div>
      <div class="flex flex-col gap-4">
        <div class="text-xl mx-auto">
          Register with...
        </div>
        <div class="flex flex-row gap-2 justify-center">
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
        <LiveRedirect class="btn btn-link btn-sm w-full" to={Routes.login_path(Endpoint, :new)}>
          Log In
        </LiveRedirect>
      </div>
    </AuthLayout>
    """
  end
end
