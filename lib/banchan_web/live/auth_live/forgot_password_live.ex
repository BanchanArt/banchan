defmodule BanchanWeb.ForgotPasswordLive do
  @moduledoc """
  Account Forgot Password?
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form

  alias Banchan.Accounts

  alias BanchanWeb.AuthLive.Components.AuthLayout
  alias BanchanWeb.Components.Form.{EmailInput, Submit}
  alias BanchanWeb.Endpoint

  @impl true
  def render(assigns) do
    ~F"""
    <AuthLayout flashes={@flash}>
      <Form class="flex flex-col gap-4" for={%{}} as={:user} submit="submit">
        <h1 class="text-2xl">Forgot your password?</h1>
        <p>If you have an account, instructions for password reset will be sent to it.</p>
        <EmailInput name={:email} icon="envelope" opts={required: true} />
        <Submit class="w-full" label="Send Instructions" />
      </Form>
    </AuthLayout>
    """
  end

  @impl true
  def handle_event("submit", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &Routes.reset_password_url(Endpoint, :edit, &1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    socket =
      socket
      |> put_flash(
        :info,
        "If your email is in our system, you will receive instructions to reset your password shortly."
      )
      |> push_navigate(to: Routes.home_path(Endpoint, :index))

    {:noreply, socket}
  end
end
