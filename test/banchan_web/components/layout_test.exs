defmodule BanchanWeb.Components.NavTest do
  @moduledoc """
  Tests for the Layout component
  """
  use BanchanWeb.ComponentCase

  alias BanchanWeb.Components.Layout

  test "renders flash component" do
    html =
      render_surface do
        ~F"""
        <Layout uri="https://example.com" current_user={nil} flashes={%{}} />
        """
      end

    assert html =~ """
           <div class="flash-container">
           """
  end

  test "renders nav component" do
    html =
      render_surface do
        ~F"""
        <Layout uri="https://example.com" current_user={nil} flashes={%{}} />
        """
      end

    assert html =~ "<nav "
  end
end
