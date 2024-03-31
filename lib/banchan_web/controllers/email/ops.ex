defmodule BanchanWeb.Email.Ops do
  @moduledoc """
  Emails for ops-related events. Typically sent to ops@banchan.art.
  """
  use BanchanWeb, :html

  def render("backup_completed.html", assigns) do
    ~F"""
    <h1>Backup completed with code {@code}.</h1>
    <pre>
    {@output}
    </pre>
    """
  end

  def render("backup_completed.text", assigns) do
    """
    Backup completed with code #{assigns.code}.

    #{assigns.output}
    """
  end
end
