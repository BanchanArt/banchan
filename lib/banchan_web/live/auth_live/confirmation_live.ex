defmodule BanchanWeb.ConfirmationLive do
  @moduledoc """
  Account Email Confirmation
  """
  use BanchanWeb, :live_view

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
        <h1 class="mx-auto text-2xl">Resend Confirmation</h1>
        <p>Email confirmation will be sent again to this address.</p>
        <EmailInput
          name={:email}
          icon="mail"
          opts={required: true, placeholder: "youremail@example.com"}
        />
        <Submit class="w-full" label="Resend" />
      </Form>
    </AuthLayout>
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
      |> push_navigate(to: Routes.home_path(Endpoint, :index))

    {:noreply, socket}
  end
end
