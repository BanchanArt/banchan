defmodule Banchan.Accounts.Notifications do
  @moduledoc """
  Notifications for account events.
  """
  import Ecto.Query, warn: false

  alias Banchan.Workers.Mailer

  @doc """
  Deliver instructions to confirm account.
  """
  def confirmation_instructions(user, url) do
    Mailer.new_email(
      user.email,
      "Confirm Your Banchan Art Email",
      BanchanWeb.Email.Accounts,
      :confirmation_instructions,
      user: user,
      url: url
    )
    |> Mailer.deliver()
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def reset_password_instructions(user, url) do
    Mailer.new_email(
      user.email,
      "Reset Your Banchan Art Email",
      BanchanWeb.Email.Accounts,
      :reset_password_instructions,
      user: user,
      url: url
    )
    |> Mailer.deliver()
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def update_email_instructions(user, url) do
    Mailer.new_email(
      user.email,
      "Update Your Banchan Art Email",
      BanchanWeb.Email.Accounts,
      :update_email_instructions,
      user: user,
      url: url
    )
    |> Mailer.deliver()
  end

  @doc """
  Deliver an artist invite email.
  """
  def artist_invite(email, url) do
    Mailer.new_email(
      email,
      "You're invited to be an artist on Banchan Art!",
      BanchanWeb.Email.Accounts,
      :artist_invite,
      url: url
    )
    |> Mailer.deliver()
  end

  @doc """
  Deliver a confirmation email after someone signs up for the beta.
  """
  def invite_request_confirmation(email) do
    Mailer.new_email(
      email,
      "You're signed up for the Banchan Art artist beta!",
      BanchanWeb.Email.Accounts,
      :invite_request_confirmation
    )
    |> Mailer.deliver()
  end
end
