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

    assert html =~ "flash-container"
  end

  test "renders success alerts" do
    html =
      render_surface do
        ~F"""
        <Flash flashes={%{"success" => "womp"}} />
        """
      end

    assert html =~
             "flash-container"

    assert html =~ "alert alert-success"
    assert html =~ "womp"
  end

  test "renders info alerts" do
    html =
      render_surface do
        ~F"""
        <Flash flashes={%{"info" => "womp"}} />
        """
      end

    assert html =~
             "flash-container"

    assert html =~ "alert alert-info"
    assert html =~ "womp"
  end

  test "renders warning alerts" do
    html =
      render_surface do
        ~F"""
        <Flash flashes={%{"warning" => "womp"}} />
        """
      end

    assert html =~
             "flash-container"

    assert html =~ "alert alert-warning"
    assert html =~ "womp"
  end

  test "renders error alerts" do
    html =
      render_surface do
        ~F"""
        <Flash flashes={%{"error" => "womp"}} />
        """
      end

    assert html =~
             "flash-container"

    assert html =~ "alert alert-error"
    assert html =~ "womp"
  end
end
