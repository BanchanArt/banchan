defmodule BanchanWeb.Components.Markdown do
  @moduledoc """
  Renders markdown text into well-styled HTML, making sure things are safely sanitized.
  """
  use BanchanWeb, :component

  prop content, :string, required: true

  def render(assigns) do
    md = assigns.content
    content = md && HtmlSanitizeEx.markdown_html(Earmark.as_html!(md))
    ~F"""
    <div class="markdown">
      {raw(content)}
    </div>
    """
  end
end
