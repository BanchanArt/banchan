defmodule BanchanWeb.Components.PickTheme do
  @moduledoc """
  Allows switching between different themes
  """
  use BanchanWeb, :live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.RadioButton

  data theme, :string, values: ["dark", "light"], default: nil

  def handle_event("change_theme", %{"theme" => theme}, socket) do
    {:noreply,
     socket
     |> assign(theme: theme)
     |> push_event("set_theme", %{theme: theme})}
  end

  def handle_event("theme_changed", %{"theme" => theme}, socket) do
    {:noreply, socket |> assign(theme: theme)}
  end

  def render(assigns) do
    ~F"""
    <bc-toggle-theme :hook="PickTheme" id={@id}>
      <Form for={%{"theme" => @theme}} change="change_theme">
        <fieldset>
          <legend class="sr-only">Theme style</legend>
          <div class="space-y-4">
            <div class="flex items-center">
              <RadioButton
                id={@id <> "-light-theme"}
                name={:theme}
                checked={@theme == "light"}
                value="light"
                class="h-4 w-4 text-neutral focus:ring-neutral"
              />
              <label for={@id <> "-light-theme"} class="ml-3 block text-sm font-medium leading-6">
                Light
              </label>
            </div>
            <div class="flex items-center">
              <RadioButton
                id={@id <> "-dark-theme"}
                name={:theme}
                checked={@theme == "dark"}
                value="dark"
                class="h-4 w-4 text-neutral focus:ring-neutral"
              />
              <label for={@id <> "-dark-theme"} class="ml-3 block text-sm font-medium leading-6">
                Dark
              </label>
            </div>
          </div>
        </fieldset>
      </Form>
    </bc-toggle-theme>
    """
  end
end
