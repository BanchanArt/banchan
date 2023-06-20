defmodule BanchanWeb.Email.LayoutHTML do
  @moduledoc """
  Layout wrapper for emails, for legacy compatibility with `Bamboo.Phoenix.put_html_layout/2`
  """
  use BanchanWeb, :html

  def render("email", assigns) do
    BanchanWeb.Layouts.email(assigns)
  end
end
