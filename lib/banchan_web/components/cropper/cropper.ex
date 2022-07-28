defmodule BanchanWeb.Components.Cropper do
  @moduledoc """
  Image cropper component for previewing images and cutting them down to size.
  """
  use BanchanWeb, :component

  prop id, :string, required: true
  prop upload_config, :struct, required: true
  prop upload, :struct, required: true
  prop aspect_ratio, :number
  prop class, :css_class

  def render(assigns) do
    ~F"""
    <img class={@class} :hook="Cropper" id={@id <> "-img"} data-upload-name={@upload_config.name} data-entry-ref={@upload.ref} data-upload-ref={@upload.upload_ref} data-aspect-ratio={@aspect_ratio} phx-update="ignore">
    """
  end
end
