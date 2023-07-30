defmodule BanchanWeb.Components.Stats.Stat do
  @moduledoc """
  Component for displaying stats, based on the TailwindUI components at:
  https://tailwindui.com/components/application-ui/data-display/stats
  """
  use BanchanWeb, :component

  prop id, :string
  prop name, :string, required: true
  prop subtext, :string
  prop value, :any, required: true

  slot default

  def render(assigns) do
    ~F"""
    <div
      id={@id}
      class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-2 px-4 py-8 sm:px-6 xl:px-8"
    >
      <dt class="text-sm font-medium leading-6 text-base-content opacity-50">{@name}</dt>
      <dd :if={!is_nil(@subtext)} class="text-xs font-medium text-base-content opacity-50">
        {@subtext}
      </dd>
      <dd class="w-full flex-none flex-col text-3xl font-medium leading-10 tracking-tight text-base-content">
        <div class="flex flex-col">
          <span>{@value}</span>
          <#slot />
        </div>
      </dd>
    </div>
    """
  end
end

defmodule BanchanWeb.Components.Stats do
  @moduledoc """
  Component for displaying stats, based on the TailwindUI components at:
  https://tailwindui.com/components/application-ui/data-display/stats
  """
  use BanchanWeb, :component

  prop class, :css_class

  slot default

  def render(assigns) do
    ~F"""
    <dl class={"grid grid-cols-1 divide-y overflow-hidden md:divide-x md:divide-y-0 md:grid-cols-3", @class}>
      <#slot />
    </dl>
    """
  end
end
