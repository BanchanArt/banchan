defmodule BanchanWeb.UserRegistrationController do
  use BanchanWeb, :controller

  alias Phoenix.LiveView

  alias Banchan.Accounts
  alias BanchanWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, _} ->
        conn
        |> put_flash(:error, "Registration failed")
        |> LiveView.Controller.live_render(BanchanWeb.RegisterLive, session: user_params)
    end
  end
end
