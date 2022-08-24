defmodule BanchanWeb.Email.AccountsView do
  @moduledoc """
  Rendering emails related to the Accounts context.
  """
  use BanchanWeb, :view

  def render("confirmation_instructions.html", assigns) do
    ~F"""
    <p>Welcome to Banchan Art, {@user.name || @user.handle}!</p>
    <p>We are glad to have you in our community. Please verify your account by
      <a href={@url}>clicking here</a> or visiting the following URL:
    </p>
    <p>{@url}</p>
    <p>If you have any questions, feel free to email us at <a href="mailto:support@banchan.art">support@banchan.art</a>.</p>
    <p>If you didn't create an account with us please ignore this.</p>
    <p>- The Banchan Art Team</p>
    """
  end

  def render("confirmation_instructions.text", assigns) do
    """
    ==============================

    Welcome to Banchan Art, #{assigns.user.name || assigns.user.handle}!

    We are glad to have you in our community.  Please verify your account by visiting the following URL:

    #{assigns.url}

    If you have any questions, feel free to email us at support@banchan.art.

    If you didn't create an account with us, please ignore this.

    - The Banchan Art Team

    ==============================
    """
  end

  def render("reset_password_instructions.html", assigns) do
    ~F"""
    <p>Hi {@user.name || @user.handle}!</p>
    <p>You can reset your password by
      <a href={@url}>clicking here</a> or visiting the following URL:
    </p>
    <p>{@url}</p>
    <p>If you didn't request this change, please ignore this.</p>
    """
  end

  def render("reset_password_instructions.text", assigns) do
    """
    ==============================

    Hi #{assigns.user.name || assigns.user.handle},

    You can reset your password by visiting the URL below:

    #{assigns.url}

    If you didn't request this change, please ignore this.

    ==============================
    """
  end

  def render("update_email_instructions.html", assigns) do
    ~F"""
    <p>Hi {@user.name || @user.handle}!</p>
    <p>You can change your email by
      <a href={@url}>clicking here</a> or visiting the following URL:
    </p>
    <p>{@url}</p>
    <p>If you didn't request this change, please ignore this.</p>
    """
  end

  def render("update_email_instructions.text", assigns) do
    """
    ==============================

    Hi #{assigns.user.name || assigns.user.handle},

    You can change your email by visiting the URL below:

    #{assigns.url}

    If you didn't request this change, please ignore this.

    ==============================
    """
  end

  def render("artist_invite.html", assigns) do
    ~F"""
    <p>Congratulations! You've been invited to become an artist on <a href="https://banchan.art">Banchan Art</a>!</p>
    <p>Accepting this invite will allow you to create studios and start accepting commissions right away, as well as getting your studios and offerings listed across the site.</p>
    <p>To accept the invite, <a href={@url}>click here</a> or visit the following URL:</p>
    <p>{@url}</p>
    <p>If you didn't sign up for this, or aren't expecting someone else to invite you, please ignore this.</p>
    <p>- The Banchan Art Team</p>
    """
  end

  def render("artist_invite.text", assigns) do
    """
    ==============================

    Congratulations! You've been invited to become an artist on Banchan Art!

    Accepting this invite will allow you to create studios and start accepting commissions right away, as well as getting your studios and offerings listed across the site.

    To accept the invite, visit the following URL:

    #{assigns.url}

    If you didn't sign up for this, or aren't expecting someone else to invite you, please ignore this.

    - The Banchan Art Team

    ==============================
    """
  end

  def render("invite_request_confirmation.html", assigns) do
    ~F"""
    <p>You've successfully signed up for the Banchan Art beta waiting list.</p>
    <p>When it's your turn, we'll send you an email with a link you can use to flag your Banchan account as an artist, which will let you make your own studios and start accepting commissions.</p>
    <p>In the meantime, you can <a href="https://discord.gg/FUkTHjGKJF">Join us on Discord</a> or <a href="https://twitter.com/BanchanArt">Follow us on Twitter</a> to stay up to date on the latest news.</p>
    <p>If you didn't sign up for this, or aren't expecting someone else to invite you, please ignore this.</p>
    <p>- The Banchan Art Team</p>
    """
  end

  def render("invite_request_confirmation.text", _assigns) do
    """
    ==============================

    You've successfully signed up for the Banchan Art beta waiting list.

    When it's your turn, we'll send you an email with a link you can use to flag your Banchan account as an artist, which will let you make your own studios and start accepting commissions.

    In the meantime, you can Join us on Discord (https://discord.gg/FUkTHjGKJF) or Follow us on Twitter (https://twitter.com/BanchanArt) to stay up to date on the latest news.

    If you didn't sign up for this, or aren't expecting someone else to invite you, please ignore this.

    - The Banchan Art Team

    ==============================
    """
  end
end
