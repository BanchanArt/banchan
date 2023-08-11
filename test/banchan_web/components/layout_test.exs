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
        <Layout flashes={%{}} />
        """
      end

    assert html =~ """
           <div class="fixed w-auto w-2/5 toast toast-center flash-container">
           """
  end

  test "renders nav component" do
    html =
      render_surface do
        ~F"""
        <Layout flashes={%{}} />
        """
      end

    assert html =~ "<nav "
  end
end
