defmodule Banchan.Accounts.UserNotifier do
  @moduledoc false

  alias Bamboo.Email

  alias Banchan.Mailer

  defp deliver(to, subject, body) do
    Email.new_email(
      to: to,
      from:
        "noreply@" <>
          (Application.get_env(:banchan, Banchan.Mailer)[:sendgrid_domain] || "banchan.art"),
      subject: subject,
      text_body: body
    )
    |> Mailer.deliver_later!()

    {:ok, %{to: to, body: body}}
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirm Your Banchan Art Email", """

    ==============================

    Hi #{user.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset Your Banchan Art Email", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update Your Banchan Art Email", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
