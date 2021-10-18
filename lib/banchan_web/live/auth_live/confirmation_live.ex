defmodule BanchanWeb.ConfirmationLive do
  @moduledoc """
  Account Email Confirmation
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
      <h1 class="text-2xl">Resend confirmation instructions</h1>
      <Form for={:user} submit="submit">
        <Field class="field" name={:email}>
          <Label class="label" />
          <div class="control">
            <EmailInput opts={required: true} />
          </div>
          <ErrorTag class="help is-danger" />
        </Field>
        <Submit label="Resend confirmation information" />
      </Form>
    </Layout>
    """
  end

  @impl true
  def handle_event("submit", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(Endpoint, :confirm, &1)
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    socket =
      socket
      |> put_flash(
        :info,
        "If your email is in our system and it has not been confirmed yet, " <>
          "you will receive an email with instructions shortly."
      )
      |> push_redirect(to: Routes.home_path(Endpoint, :index))

    {:noreply, socket}
  end
end
