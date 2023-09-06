defmodule BanchanWeb.Components.RichText do
  @moduledoc """
  Renders rich text into well-styled HTML, making sure things are safely sanitized.
  """
  use BanchanWeb, :component

  prop content, :string, required: true
  prop class, :css_class

  def render(assigns) do
    text = assigns.content
    content = text && HtmlSanitizeEx.basic_html(text)

    ~F"""
    <div class={"prose", @class}>
      {raw(content)}
    </div>
    """
  end
end
