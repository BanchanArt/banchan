defmodule BanchanWeb.Components.FlashTest do
  @moduledoc """
  Tests for the Flash component
  """
  use BanchanWeb.ComponentCase

  alias BanchanWeb.Components.Flash

  test "doesn't render any string if there's no flashes" do
    html =
      render_surface do
        ~F"""
        <Flash flashes={%{}} />
        """
      end

    assert html =~ """
           <p phx-value-key="info" phx-click="lv:clear-flash" class="alert alert-info" role="alert"></p>
           <p phx-value-key="error" phx-click="lv:clear-flash" class="alert alert-danger" role="alert"></p>
           """
  end

  test "renders info alerts" do
    html =
      render_surface do
        ~F"""
        <Flash flashes={%{"info" => "womp"}} />
        """
      end

    assert html =~ """
           <p phx-value-key="info" phx-click="lv:clear-flash" class="alert alert-info" role="alert">womp</p>
           <p phx-value-key="error" phx-click="lv:clear-flash" class="alert alert-danger" role="alert"></p>
           """
  end

  test "renders error alerts" do
    html =
      render_surface do
        ~F"""
        <Flash flashes={%{"error" => "womp"}} />
        """
      end

    assert html =~ """
           <p phx-value-key="info" phx-click="lv:clear-flash" class="alert alert-info" role="alert"></p>
           <p phx-value-key="error" phx-click="lv:clear-flash" class="alert alert-danger" role="alert">womp</p>
           """
  end
end
