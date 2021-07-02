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
        <Nav current_user={nil} />
        """
      end

    assert html =~ "Log in"
  end

  test "renders logout stuff when logged in" do
    html =
      render_surface do
        ~F"""
        <Nav current_user={%{email: "abc@example.com"}} />
        """
      end

    assert html =~ "Log out"
  end

end
