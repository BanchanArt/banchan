defmodule BanchanWeb.Components.StatusBadge do
  @moduledoc """
  Used to show various statuses in a consistent way.
  """
  use BanchanWeb, :component

  prop class, :css_class
  prop label, :string, required: true
  prop status, :atom, required: true, values: [:success, :warning, :error, :info, :neutral]

  def render(assigns) do
    ~F"""
    <p class={
      "bg-opacity-20 rounded-md whitespace-nowrap mt-0.5 px-1.5 py-0.5 text-xs font-medium ring-1 ring-inset",
      "bg-#{@status}",
      @class
    }>
      {@label}
    </p>
    """
  end
end
