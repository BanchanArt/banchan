defmodule BanchanWeb.Components.Form.CropUploadInput do
  @moduledoc """
  Image cropper component for previewing images and cutting them down to size.
  """
  use BanchanWeb, :live_component

  alias Surface.Components.LiveFileInput

  alias BanchanWeb.Components.{Button, Modal}

  prop upload, :struct, required: true
  prop target, :string, default: "live_view"
  prop title, :string, default: "Crop Image"
  prop aspect_ratio, :number
  prop class, :css_class

  def handle_event("file_chosen", _, socket) do
    Modal.show(socket.assigns.id <> "-modal")
    {:noreply, push_event(socket, "file_chosen", %{id: socket.assigns.id})}
  end

  def handle_event("submit", _, socket) do
    Modal.hide(socket.assigns.id <> "-modal")
    {:noreply, push_event(socket, "submit", %{id: socket.assigns.id})}
  end

  def render(assigns) do
    ~F"""
    <div
      id={@id}
      :hook="CropUploadInput"
      data-upload-name={@upload.name}
      data-upload-target={@target}
      data-aspect-ratio={@aspect_ratio}
    >
      <input type="file" :on-change="file_chosen" class={"file-input", @class}>
      <LiveFileInput upload={@upload} class="hidden" />
      <Modal id={@id <> "-modal"} always_render_body>
        <:title>{@title}</:title>
        <div id={@id <> "-image-container"} phx-update="ignore" class="cropper-preview" />
        <div id={@id <> "-image-rotation"} phx-update="ignore" class="flex flex-col">
          <label class="label">
            Rotate
          </label>
          <input
            type="range"
            min="0"
            max="360"
            step="1"
            value="0"
            class="rotate-range range range-primary"
          />
        </div>
        <:action>
          <Button click="submit">Done</Button>
        </:action>
      </Modal>
    </div>
    """
  end
end
