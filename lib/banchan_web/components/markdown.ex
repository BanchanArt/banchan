defmodule BanchanWeb.Components.Markdown do
  @moduledoc """
  Renders markdown text into well-styled HTML, making sure things are safely sanitized.
  """
  use BanchanWeb, :component

  prop content, :string, required: true
  prop class, :css_class

  def render(assigns) do
    md = assigns.content
    content = md && HtmlSanitizeEx.markdown_html(Earmark.as_html!(md))

    ~F"""
    <div class={"prose", @class}>
      {raw(content)}
    </div>
    """
  end
end
