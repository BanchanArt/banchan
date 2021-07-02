defmodule BanchanWeb.ComponentCase do
  @moduledoc """
  This module defines the test case to be used by
  tests for stateless Surface components.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Surface.LiveViewTest

      # The default endpoint for testing
      @endpoint BanchanWeb.Endpoint
    end
  end
end
