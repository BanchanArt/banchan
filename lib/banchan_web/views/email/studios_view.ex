defmodule BanchanWeb.Email.StudiosView do
  @moduledoc """
  Rendering emails related to the Studios context.
  """
  use BanchanWeb, :view

  def render("studio_deleted.html", assigns) do
    ~F"""
    <p>Hi {@member.name || @member.handle}!</p>
    <p>Your studio, {@studio.name}, has been deleted by {@actor.name || @actor.handle}.</p>
    <p>If you have any questions, or if you believe this was done by mistake, please contact <a href="mailto:support@banchan.art">support@banchan.art</a> right away.</p>
    <p>- The Banchan Art Team</p>
    """
  end

  def render("studio_deleted.text", assigns) do
    """
    Hi #{assigns.member.name || assigns.member.handle}!

    Your studio, #{assigns.studio.name}, has been deleted by #{assigns.actor.name || assigns.actor.handle}.

    If you have any questions, or if you believe this was done by mistake, please contact support@banchan.art right away.

    - The Banchan Art Team
    """
  end
end
