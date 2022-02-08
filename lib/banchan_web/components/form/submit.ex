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
          class={"btn text-center rounded-full py-1 px-5 btn-primary m-1", @class}
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
