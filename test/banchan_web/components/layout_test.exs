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
           <div class="fixed bottom-auto w-auto w-3/5 translate-y-0 toast toast-center top-20 flash-container">
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
