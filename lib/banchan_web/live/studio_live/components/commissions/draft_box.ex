defmodule BanchanWeb.StudioLive.Components.Commissions.DraftBox do
  @moduledoc """
  Component for rendering the latest submitted draft on the commission page
  """
  use BanchanWeb, :live_component

  alias BanchanWeb.StudioLive.Components.Commissions.MediaPreview

  prop commission, :struct, required: true
  prop studio, :struct, required: true

  data previewing, :struct, default: nil

  def update(assigns, socket) do
    {:ok, socket |> assign(assigns)}
  end

  def render(assigns) do
    ~F"""
    <div class="h-20 border border-neutral rounded-box p-2 mb-4">
      <MediaPreview id="draft-preview" commission={@commission} studio={@studio} />
    </div>
    """
  end
end
