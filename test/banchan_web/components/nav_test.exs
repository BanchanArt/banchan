defmodule BanchanWeb.Components.SessionTest do
  @moduledoc """
  Tests for the Session component
  """
  use BanchanWeb.ComponentCase

  alias BanchanWeb.Components.Nav

  test "renders login stuff when logged out" do
    html =
      render_surface do
        ~F"""
        <Nav uri="https://example.com" current_user={nil} />
        """
      end

    assert html =~ "Log in"
  end
end
