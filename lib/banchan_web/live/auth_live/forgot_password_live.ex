defmodule BanchanWeb.ForgotPasswordLive do
  @moduledoc """
  Account Forgot Password?
  """
  use BanchanWeb, :surface_view

  alias Surface.Components.Form
  alias Surface.Components.Form.{EmailInput, ErrorTag, Field, Label, Submit}

  alias Banchan.Accounts
  alias BanchanWeb.Components.Layout
  alias BanchanWeb.Endpoint

  @impl true
  def mount(_params, session, socket) do
    socket = assign_defaults(session, socket, false)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout current_user={@current_user} flashes={@flash}>
      <h1 class="title">Forgot your password?</h1>
      <Form for={:user} submit="submit">
        <Field name={:email}>
          <Label />
          <EmailInput opts={required: true} />
          <ErrorTag />
        </Field>
        <Submit label="Send instructions to reset password" />
      </Form>
    </Layout>
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
    socket
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> push_redirect(to: Routes.home_path(Endpoint, :index))

    {:noreply, socket}
  end
end
