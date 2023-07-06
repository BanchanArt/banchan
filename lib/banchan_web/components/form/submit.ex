defmodule BanchanWeb.Components.Form.Submit do
  @moduledoc """
  Canonical Submit button for Banchan
  """
  use BanchanWeb, :component

  alias Surface.Components.Form.Submit

  prop changeset, :any
  prop label, :string, default: "Submit"
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <div class="field">
      <div class="control">
        <Submit
          class={"btn btn-loadable text-center btn-primary", @class}
          label={@label}
          opts={
            disabled: @changeset && (Enum.empty?(@changeset.changes) || !@changeset.valid?)
          }
        />
      </div>
    </div>
    """
  end
end
