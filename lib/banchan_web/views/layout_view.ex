defmodule BanchanWeb.LayoutView do
  use BanchanWeb, :view

  def render(_, assigns) do
    ~F"""
    <!DOCTYPE html />
    <html lang="en">
      <head>
        <meta charset="utf-8">
        {Phoenix.HTML.Tag.csrf_meta_tag()}
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        {live_title_tag(assigns[:page_title] || "Banchan Art")}
        <link phx-track-static rel="stylesheet" href={Routes.static_path(@conn, "/css/app.css")}>
        <script
          defer
          phx-track-static
          type="text/javascript"
          src={Routes.static_path(@conn, "/js/app.js")}
        />
      </head>
      <body class="">
        {@inner_content}
      </body>
    </html>
    """
  end
end
